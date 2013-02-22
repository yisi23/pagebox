# OriginMap: Tool & Guard
## What is OriginMap?

![](http://f.cl.ly/items/3l443C1V123c1c0G273p/demo.png)
This is a concept of bulletproof web applications. Web is not perfect. Web is far from perfect. Web is broken: Cookies, Clickjacking, Frame navigation, CSRF,  .
Here is why:

![](http://f.cl.ly/items/1q1I2f2N1o161D1o3f3G/somthn.png)

OriginMap *splits* the entire website into many pages with unique origins. Every page has its own Origin in terms of frame navigation - you simply cannot `window.open` or iframe it and extract `document.body.innerHTML`. Also every page contains additional `OriginMapObject` in `<meta>` tag, and sends it with every `XMLHttpRequest` and `<form>` submission. `OriginMapObject` has `url` property - current page URL (not location.href which can be changed with history.pushState), `perms` - permissions granted for this page and `params` - restricting specific params values to simplify business logic.

## OriginMap: Next level of XSS protection
The idea i'm implementing prototype of is OriginMap. When we find XSS at /some_path we can pwn and do requests and read responses from anywhere on the whole website on this domain. I want to change this situation by adding Authorization technology for pages. Every page will have unique origin and will serve header:
```
Content-Security-Policy: sandbox;
```
this will disallow hacked `/some_path` to extract content from `/secret` or make requests.
Implementations can vary, for example we can add such helper to `<head>`
```
<meta name="permissions" content="following,edit_account,new_status--SIGNATURE">
```
Where SIGNATURE is HMAC, in same way cookie is signed in Rails.
With each request server side will check if `current_page_permissions.include?(:following)` and if it does - perform the action.
This will dramatically improve XSS protection because XSS at /some_path will be basically useless if this some_path has no permissions.





## Content Security Policy
OriginMap takes adventadge of it. But CSP on itself is not panacea from XSS at all. 

## With OriginMap:


## Types of OriginMap

URL-based

Permissions-based

Signed params-based





# Wait is it for security only?
Here is the sweet part: Not only! This can change the way you write business logic. View template can look like:
```
form_for(current_user)
  -om_perms[:users] << current_user.id
  -for website in current_user.websites 
    edit website..
    -om_perms[:websites] << website.id
```

Look at generated origin map:
```
{
	url: "/update_account",
	perms: {
    users: [3532],
    websites: [345,346,348] 
  }
}
```
This origin map allows user to update only User with 3532 id and websites with id in (345,346,348). No server side validation is needed anymore - OM is signed with private key and user cannot tamper given map with permitted ids.



