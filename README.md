# OriginMap: Tool & Guard
## What is OriginMap?

XHR demo - on the left Red arrows are arbitary requests attacker can do. on the right we map origins and restrict access

![XHR](http://f.cl.ly/items/0y3n0a3C261X2Y3X1V2q/demo%20\(1\).png)

Frames and windows same-origin demo - Sandbox CSP header denies all same-domain interaction, use postMessage instead:

![frames](http://f.cl.ly/items/3i152w2l243d2W1r0K3P/sameorig.png)

Permitted origins demo - how meta tag has information on what was permitted to this URL.

![permitted URLs](http://f.cl.ly/items/2s2B060O1d0N1D3b0U1B/somthn%20\(1\).png)

## Bulletproof web application
This is a concept of **bulletproof web applications**. Web is not perfect. Web is far from perfect. Web is broken: Cookies, Clickjacking, Frame navigation, CSRF,  links..

OriginMap **splits** the entire website into many pages with unique origins. Every page has its own Origin in terms of frame navigation - you simply **cannot** `window.open/<iframe>` other pages on the same domain to extract `document.body.innerHTML` because of header CSP: Sandbox.

Also every page contains additional `OriginMapObject` in `<meta>` tag, and sends it along with every `XMLHttpRequest` and `<form>` submission. 

**OriginMapObject** is **signed JSON** payload containing `url` property - current page URL (not `location.href` which can be changed with history.pushState), `perms` - permissions granted for this page and `params` - restricting specific params values to simplify server-side business logic.

##Attack Surface.
Now any XSS pwns the entire website:
1 page surface * amount of all pages.

With OriginMap XSS can only pwn functionaly available for XSS-ed page: 
1 page surface * amount of pages that serve given functionality.

## Next level of XSS protection
The idea I'm implementing prototype of is to make every page **independent and secure** from others, probably vulnerable pages located on the same domain. 

When we find XSS at `/some_path` we do requests and read responses from anywhere on the whole website on this domain. 

XSS on `/about`, which is just a static page not using server side at all **leads to stolen money on `/withdraw`.**

**This is wrong.**

I want to change the current situation by adding *Authorization technology* for pages. Every page will have it's own unique origin and will serve such header:
```
Content-Security-Policy: sandbox;
```
this will disallow hacked `/some_path` to extract content from `/secret` and make requests on other endpoints.

Implementations of the concept can be different, for example we can add such meta tag to `<head>`, just like Rails adds csrf tokens
```
<meta name="permissions" content="following,edit_account,new_status--SIGNATURE">
```
Where SIGNATURE is HMAC, signed same way as Rails cookie.
With each request server side will check something like `if current_page_permissions.include?(:following)` or with more handy DSL.

This will dramatically improve **complex websites** security (like facebook, paypal or google), which are often pwned with ridiculously simple XSSes on static pages or with external libraries' vulnerabilities. 

XSS at /some_path will be basically **useless** if this /some_path has no granted permissions.

## Content Security Policy
OriginMap takes adventadge of it. But CSP on itself is not panacea from XSS, here is why...

## OriginMap advantadges:
...

## Types of OriginMap

* URL-based
* Permissions-based
* Signed params-based


# It's so cool, Egor! Can I start using it to make my app super secure?
The thing is, you **cannot differ XMLHttpRequest from normal browser request**. XHR: 
`x=new XMLHttpRequest;x.open('get','payments/new');x.send();`
can read responseText of **any** page because we cannot detect the initiator of a request, was it you opening a new tab or was it attacker's XSS. He can read `<meta>` containing any origin_map. This makes OriginMap technique not usable. Sorry.

This is a very bad problem because we cannot restrict access and it simply bypasses sendbox for GETting data.
By now we only can sendbox writing data.
I hope browsers will add a reliable header for XHR.

## Bonus: OriginMap 2.0 as view-based business logic. (possible feature)
Here is another sweet feature: it can change the way you write business logic. Template can look like this:
```
form_for(current_user)
  -om_perms[:users] << current_user.id
  -for website in current_user.websites 
    edit website..
    -om_perms[:websites] << website.id
```
or even simpler
```
form_for(current_user, signed_data: {id: current_user.id})
```

This will generate such origin map:
```
{
	url: "/update_account",
	perms: {
    users: [3532],
    websites: [345,346,348] 
  }
}
```
The map allows user to update **only** User with 3532 id and websites with id in (345,346,348). No server side validation is needed anymore - OM is signed with private key and user cannot tamper given map with permitted ids.

This may sound not very secure - **compromise of server_secret == compromise of business logic** but we can polish the idea and take the security risk, cannot we?

The whole concept is under heavy development, as well as rack prototype. Please share your thoughts at homakov@gmail.com. 



