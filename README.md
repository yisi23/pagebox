# OriginMap: Tool & Guard

![XHR](http://f.cl.ly/items/0y3n0a3C261X2Y3X1V2q/demo%20\(1\).png)

OriginMap is a revolutionary technique (trust me im [an infosec engineer](http://homakov.blogspot.com)) which can dramatically improve XSS protection and overall access restrictions for huge, complex and multi-layer websites.

**OriginMap** is a technique for **bulletproof web applications**. Web is not perfect, far from perfect: [Cookies](http://homakov.blogspot.com/2013/02/rethinking-cookies-originonly.html), [Clickjacking](http://homakov.blogspot.com/2012/06/saferweb-with-new-features-come-new.html), [Frame navigation](http://homakov.blogspot.com/2013/02/cross-origin-madness-or-your-frames-are.html), [CSRF](http://homakov.blogspot.com/2012/03/hacking-skrillformer-moneybookers.html) etc
Speaking about XSS web is **just broken**.

When we find XSS at `/some_path` we can make authorized requests and read responses from **anywhere on the whole website** on this domain. 

XSS on `/about`, which is just a static page not using server side at all **leads to stolen money on `/withdraw`.**

**This is not cool.**
## Next level of XSS protection: Page Scope
The idea I'm implementing is to make every page **independent and secure** from others, potentionally vulnerable pages located on the same domain. To make website work developer creates an origin map - he connects **page origins** with **what they are allowed to do**. 

OriginMap **splits** the entire website into many pages with unique origins. Every page is not accessible from other pages unless developer allowed it explicitly - you simply **cannot** `window.open/<iframe>` other pages on the same domain and extract `document.body.innerHTML` because of the header CSP: `Sandbox`. It disallows all "samedomain" interactions - use a secure technique `postMessage` instead.

![frames](http://f.cl.ly/items/3i152w2l243d2W1r0K3P/sameorig.png)

Also every page contains additional origin map Container in `<meta>` tag (Implementations of the concept can vary, this is how Rails adds csrf tokens), and sends it along with every `XMLHttpRequest` and `<form>` submission. It is **a signed serialized object** (e.g. with JSON)  containing various values. **Meta tag contains signed information about what was permitted for this URL.**

It can be: `url` property - original page URL (not `location.href` which can be compromised with history.pushState), `perms` - permissions granted for this page and `params` - restricting specific params values to simplify server-side business logic. 

**PageScope** is a ruby implementation or permission-based OriginMap conception. Every page has 'scope' dedicated for this origin. Page can only execute request authorized for scope this page has. Scope can look like: `["follow", "write_message", "read_messages", "edit_account", "delete_account"]`. Or it can be more high-level:
`["default", "basic", "edit_resource", "show_secret"]`

Server side checks container integrity and authorizes request if permission was granted.

![permitted URLs](http://f.cl.ly/items/2s2B060O1d0N1D3b0U1B/somthn%20\(1\).png)

# FAQ

## Signature
```
<meta name="permissions" content="following,edit_account,new_status--SIGNATURE">
```
Where SIGNATURE is HMAC, signed same way as Rails cookie.
With each request server side will check something like `if current_page_permissions.include?(:following)` or with more handy DSL.

## Attack Surface.
Before any XSS could pwn the entire website:

`1 page surface * amount of all pages.`

With OriginMap XSS can only pwn functionaly available for XSS-ed page: 

`1 page surface * amount of pages that serve given functionality.`

## Content Security Policy

OriginMap takes adventadge of it. But CSP on itself is not panacea from XSS: DOM XSS (there are always a lot of ways to insert HTML leading to execution), [JSONP bypasses](http://homakov.blogspot.com/2013/02/are-you-sure-you-use-jsonp-properly.html)

## Rely on Referrer as OriginPage header

When I see someone using [referrer as a security measurement I want to cry](http://homakov.blogspot.com/2012/04/playing-with-referer-origin-disquscom.html).

## Subdomains

Yes you can use subdomains to extract functionality. You can end up with:

1) follow.site.com

2) transfermoney.site.com

3) readmessages.site.com

4) createapost.site.com

... Also at the end of the day I will hack your Single Sign On. :trollface:

## Rich Internet Applications

If your app consists of one or two pages this feature **will not** decrease attack surface a lot because what **all possible functionality** was granted to this single page.

## So which apps need it the most?

This will dramatically improve **complex websites** security (like facebook, paypal or google), which are often pwned with ridiculously simple XSSes on static/legacy pages or with external libs vulnerabilities(for example copy-paste swf file).

XSS at /some_path will be basically **useless** if this /some_path has no granted explicitely permissions. 

If you don't permit anything for /static/page you can leave an XSS reflector and make fun of script kiddies trying to exploit other pages with it.

## Types of OriginMap

### URL-based

Detection of given permissions by checking origin page url. 
`perms << :edit_account if origin_url == '/edit_account'`

### Permissions-based

When you create and sign permissions **in views**.
```
-om_perm << :edit_account
=form_for current_user
  ..here we edit current user
```
### Signed params-based
When you sign params and some of their constant values. Like strong_params but views-based. Feature for 2 version, maybe.

## Can I start using it to make my app super secure NOW?
The thing is, you **cannot differ XMLHttpRequest from normal browser request**. XHR: 
`x=new XMLHttpRequest;x.open('get','payments/new');x.send();`
can read responseText of **any** page because we cannot detect the initiator of the request - was it just a new tab or was it attacker's XSS stealing content. Thus he can read `<meta>` containing any origin_map -> execute any POST authorized with any origin_map. This makes OriginMap technique harder. 

## XSS in real world? 

Open responsible disclosure page and see bugs disclosed by whitehats. Now double it and this is amount of bugs found by blackhats. They might not be using it right now, but if your app gets popular and it becomes profitable to exploit an XSS - it will punch you. 

Doesn't it sound funny to let your customers lose money/be spamed because of XSS on the page you don't even remember about? 

You **need** OriginMap protection - this is investment for your continous website safety and structure.

# Bonus: OriginMap 2.0 as view-based business logic. (a possible feature)
Here is another sweet feature: it can change the way you write business logic. Template can look like this:
```
form_for(current_user)
  -om_perms[:users] << current_user.id
  -for website in current_user.websites 
    edit website..
    -om_perms[:websites] << website.id
```
or even simpler DSL
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



