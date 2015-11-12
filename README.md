# Enhanced-HTML-Helper
The Enhanced HTML Helper is a CFC that abstracts the creation of any HTML entity. It provides consistent and secure rendering of HTML. 

There is no special setup needed to use it in a ColdBox application, it's already baked in. Just reference the object by the html prefix and call the desired function:

```
// CFML
#html.button(name = "searchView", value = "View")#

// HTML Output
<button name="searchView" id="searchView" type="button">View<button>
```

Documentation is available as a [GitBook](https://www.gitbook.com/book/iknowkungfoo/coldbox-html-helper/details).
