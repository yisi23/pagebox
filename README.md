#OriginMap: Next level of XSS protection
# Sakurity OriginMap

## What is OriginMap?
This is a concept of bulletproof web applications. Web is not perfect. Web is far from perfect. Web is broken: Cookies, Clickjacking, Frame navigation, CSRF,  .
Here is why:





## Content Security Policy
OriginMap takes adventadge of it. But CSP on itself is not panacea from XSS at all. 

## With OriginMap:


## Types of OriginMap

URL-based

Permissions-based

Signed params-based






The idea I'm implementing prototype of is OriginMap. When we find XSS at /some_path we can pwn and do requests and read response the whole website on this domain. I want to change this situation by adding Authorization technology for pages. Every page will have unique origin and will serve header:
Content-Security-Policy: sandbox;
this will disallow hacked /some_path to extract content from /secret or make requests.
Implementations can vary, for example we can add such helper to <head>
<meta name="permissions" content="following,edit_account,new_status--SIGNATURE">
Where SIGNATURE is HMAC, in same way cookie is signed in Rails.
With each request server side will check if current_page_permissions.include?(:following) and if it does - perform the action.
This will dramatically improve XSS protection because XSS at /some_path will be basically useless if this some_path has no permissions.


