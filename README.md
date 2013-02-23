[Pagebox — website gatekeeper. Blogpost with description.](http://homakov.blogspot.com/2013/02/pagebox-website-gatekeeper.html)

# FAQ

## Signature
```
<meta name="pagebox" content="WyJkZWZhdWx0Iiwic3RhdGljIl0=--c8303f09f8a5e2ac9b70d5b4dbdc44ca25c97c8a">
```
HMAC, signed same way as Rails cookie.

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

Pagebox protection - is investment in website safety.

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