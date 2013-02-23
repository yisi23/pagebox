# Pagebox — website gatekeeper.

![XHR](http://f.cl.ly/items/0y3n0a3C261X2Y3X1V2q/demo%20\(1\).png)

**Pagebox** is a technique for bulletproof web applications, which can dramatically improve XSS protection for complex and multi-layer websites with huge attack surface.

Web is not super robust ([Cookies](http://homakov.blogspot.com/2013/02/rethinking-cookies-originonly.html), [Clickjacking](http://homakov.blogspot.com/2012/06/saferweb-with-new-features-come-new.html), [Frame navigation](http://homakov.blogspot.com/2013/02/cross-origin-madness-or-your-frames-are.html), [CSRF](http://homakov.blogspot.com/2012/03/hacking-skrillformer-moneybookers.html) etc) but **XSS is an Achilles' heel**, it is a shellcode for the entire domain.

When we find XSS at `/some_path` we can make authorized requests and read responses from **anywhere on the whole website** on this domain. XSS on `/about`, which is just a static page not using server side at all **leads to stolen money on `/withdraw`.** This is not cool.

## Sandboxed pages
The idea I want to implement is to make every page **independent and secure** from others, potentionally vulnerable pages located on the same domain. To make website work developer creates a pagebox - he connects **page origins** with **what they are allowed / supposed to do**. 

![frames](http://f.cl.ly/items/1l2I1s1o2U3t2y39050p/Screen%20Shot%202013-02-24%20at%203.51.27%20AM.png)

Pagebox **splits** the entire website into many sandboxed pages with unique origins. Every page is not accessible from other pages unless developer allowed it explicitly - you simply **cannot** `window.open/<iframe>` other pages on the same domain and extract `document.body.innerHTML` because of the CSP header: `Sandbox`. It disallows all DOM interactions - use `postMessage` instead.

![frames](http://f.cl.ly/items/3i152w2l243d2W1r0K3P/sameorig.png)

Every page contains **a signed serialized object** (e.g. with JSON) in `<meta>` tag (implementations of the concept can vary, this is how Rails adds csrf tokens), and sends it along with every `XMLHttpRequest` and `<form>` submission. **Meta tag contains signed information about what was permitted for this URL.**

Boxed page has assigned 'pagebox scope' and can do only allowed actions — e.g. if you have :messages scope you can read `messages.json` and POST to `/new_message`. Server side checks container integrity and executes request if permission was granted. At some extent it's more strict CSRF protection - it's Cross Page Request Forgery protection.

It can be: `url` property - original page URL (not `location.href` which can be compromised with history.pushState), `perms` - permissions granted for this page and `params` - restricting specific params values to simplify server-side business logic. 

Pagebox can look like: `["follow", "write_message", "read_messages", "edit_account", "delete_account"]`. Or it can be more high-level:
`["default", "basic", "edit", "show_secret"]`

![permitted URLs](http://f.cl.ly/items/2s2B060O1d0N1D3b0U1B/somthn%20\(1\).png)

# Problems
Now page can only submit forms, but XHR CORS doesn't work properly, perhaps because nobody knew we will try it in such way. I'm stuck with XHR-with-credentials and I need your help and ideas. 

1) Every page is sandboxed and we cannot put 'allow-same-origin' to avoid DOM interactions

2) When we sandbox a page it gets a unique origin 'null', when we make requests from 'null' we cannot attach credentials (Cookies), because wildcard ('*') [is not allowed](https://developer.mozilla.org/en-US/docs/HTTP/Access_control_CORS#Requests_with_credentials) in `Access-Control-Allow-Origin: *` for with-credentials requests.
```
when responding to a credentialed request,  server must specify a domain, and cannot use wild carding.
```

3) Neither `*` nor `null` are allowed for `Access-Control-Allow-Origin`. So XHR is not possible with Cookies from sandboxed pages.

4) I was trying to use not sandboxed /pageboxproxy iframe, which would do the trick from not sandboxed page and return result back with postMessage, but when we frame not sandboxed page under sandboxed it doesn't work either.

I don't know how to fix it but I really want to make pagebox technique work. **It fixes the Internet.**

# FAQ

## Signature
```
<meta name="pagebox" content="WyJkZWZhdWx0Iiwic3RhdGljIl0=--c8303f09f8a5e2ac9b70d5b4dbdc44ca25c97c8a">
```
HMAC, signed same way as Rails cookie.
With each request server side checks something like `if current_page_permissions.include?(:following)` or with more handy DSL.

## Attack Surface.
Before any XSS could pwn the entire website:

`1 page surface * amount of all pages.`

With Pagebox XSS can only pwn functionaly available for XSS-ed page: 

`1 page surface * amount of pages that serve given functionality.`

## Content Security Policy

CSP on itself is not panacea from XSS: DOM XSS (there are always a lot of ways to insert HTML leading to execution), [JSONP bypasses](http://homakov.blogspot.com/2013/02/are-you-sure-you-use-jsonp-properly.html), for example:
```
<a data-method="delete" data-remote="/account/delete">CLICK</a>
```

## Rely on Referrer as OriginPath header

When I see someone using [referrer as a security measurement I want to cry](http://homakov.blogspot.com/2012/04/playing-with-referer-origin-disquscom.html).

## Subdomains

Yes you can use subdomains to extract functionality. You can end up with:

1) follow.site.com

2) transfermoney.site.com

3) readmessages.site.com

4) createapost.site.com

5) transactionhistory.site.com

... at the end of the day I will hack your Single Sign On. :trollface:

## Rich Internet Applications

If your app consists of one or two pages this feature **will not** decrease attack surface because **all possible functionality** was granted to this single page.

## So which apps need it the most?

This will dramatically improve **complex websites** security (like facebook, paypal or google), which are often pwned with ridiculously simple XSSes on static/legacy pages or with external libs vulnerabilities(for example copy-paste swf file).

XSS at /some_path will be basically **useless** if this /some_path has no granted explicitely permissions. 

If you don't permit anything for /static/page you can leave an XSS reflector and make fun of script kiddies trying to exploit other pages with it.

## Types

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

## XSS is unpleasant in the wild

Open any big website "Responsible disclosure" page, look at the bugs disclosed by whitehats. Now double it and see the amount of bugs found by blackhats. They might not be using it right now, but if your app gets popular and it becomes profitable to exploit an XSS - it will punch you. 

Doesn't it sound funny to let your customers lose money/be spamed because of XSS on the page you don't even remember about? 

Pagebox protection - is investment in your current and future website safety.

# P.S. Pagebox 2.0 as view-based business logic. (a possible feature)
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
This will generate such pagebox:
```
{
	url: "/update_account",
	perms: {
    users: [3532],
    websites: [345,346,348] 
  }
}
```
The pagebox allows user to update **only** User with 3532 id and websites with id in (345,346,348). No server side validation is needed anymore - OM is signed with private key and user cannot tamper given pagebox with permitted ids. This may sound not very secure - **compromise of server_secret == compromise of business logic** but we can polish the idea and take the security risk, don't we?

The whole concept is under heavy development, as well as rack prototype. Please share your thoughts at homakov@gmail.com. 