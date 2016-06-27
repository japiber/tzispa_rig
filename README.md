# Tzispa Rig

A general purpose template engine

## Installation

```shell
% gem install tzispa
```

## Rig template types

There are 3 template types: layout, static and block:

* layout: these are the skeleton entry points of the rig templates
* static: these are "light" templates that are a included without any processing as plain text
* block: the true core of the rig templates, each block template file has an associated ruby file with the template binder class

To add templates to your app you can use cli coomands

```shell
% tzispa generate rig lister --type=layout --app=mainapp
% tzispa generate rig sitefoot --type=static --app=mainapp
% tzispa generate rig product_detail --type=block --app=mainapp
```

## Rig template language

### Variables and metavariables

Template variables are specified with:
```
<var:name/>
```

And metavariables with:
```
{%name%}
```

metavariables are used to make runtime template tags replacements
```html
<fieldset>
  <div class='row'>
    <div class='column column-80'>
      <label for='name'>Nombre *</label>
      <input type='text' name='name' id='name' maxlength="64" value='<var:name/>' required='required' />
    </div>
    <div class='column column-20'>
      <label for='skey'>Código</label>
      <input type='text' name='skey' id='skey' maxlength="16" value='<var:skey/>'/>
    </div>
    <a href='<purl:site[layout=brand_edit,title=edit-brand,id0={%idb%}]/>'><i class='fa fa-edit'></i></a>
  </div>
```

in the template binder
```ruby
def bind!
  @idb = context.router_params[:id0]
  load_brand if idb
end

private

attr_reader :idb

def load_brand
  brand = context.repository[:brand, :ecomm_shop][idb]
  data(
    idb: brand.id,
    name: brand.name,
    skey: brand.skey
  )
end
```

### Conditionals

You can make decisions in your templates using template ife tag:
```
<ife:test> ..... <else:test/> .... </ife:test>

or without the else part

<ife:test> .....  </ife:test>
```

```html
<ife:customer_exist>
  <div class='row'>
    <div class='column column-80'>
      <label for='name'>Nombre *</label>
      <input type='text' name='name' id='name' maxlength="64" value='<var:name/>' required='required' />
    </div>
    <div class='column column-20'>
      <label for='skey'>Código</label>
      <input type='text' name='skey' id='skey' maxlength="16" value='{%skey%}'/>
    </div>
  </div>
<else:customer_exist/>  
  <p> There isn't any customer here </p>
</ife:customer_exist>  
```

In the binder you must define customer_exist
```ruby

def bind!
  idc = context.router_params[:id0]
  customer = context.repository[:customer, :ecomm_shop][idb]
  data.customer_exist = !customer.nil?
end

```

## Repeating

To repeat a part in the template use loop tag
```
<loop:ltag> ... </loop:ltag>
```

```html
<loop:lbrands>
<tr>
  <td><var:id/></td>
  <td><var:skey/></td>
  <td><var:name/></td>
  <td class='text-right'>
    <a href='<purl:site[layout=brand_edit,title=edit-brand,id0={%id%}]/>'><i class='fa fa-edit'></i></a>
    <a href='javascript:delete_brand("<sapi:brand:delete:{%id%}/>")'><i class='fa fa-trash'></i></a>
  </td>
<tr>
</loop:lbrands>
```

In the binder you must use the 'loop_binder' method
```ruby

def bind!
  data.lbrands = loop_binder(:lbrands).bind!(&load_brands)
end

private

def load_brands
  Proc.new {
    context.repository[:brand, :ecomm_shop].list.map { |b|
      loop_item(
        id: b.id,
        skey: b.skey,
        name: b.name
      )
    }
  }
end
```

## Template URLs

Rig templates can build urls for you. There are 2 url types:

### purl

Site urls: used to provide links to site pages

```
<purl:route_id/>
<purl:route_id[param1=value,param2=value]/>
```

```html
<purl:site[layout=brands,title=brand-list]/>
<purl:index/>
```
The route_id's area defined in the start.ru file

### api

Api urls: used to provide urls to the application Api

```
<sapi:handler:verb/>
<sapi:handler:verb:predicate/>
```

```html
<sapi:customer:add:address/>

<sapi:brand:{%verb%}/>
```

## Building templates

You can include block and static rig templates using these tags:
```
<blk:name[param1=value,param2=value, ... ]/>

<static:name/>
```

As you can see, template parameters can be passed in the block tag.
These parameters will be available in the binder.
You can also use template subdomains using dot notation in the name
```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <blk:metasense/>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <static:comassert/>
</head>
<body>
  <blk:header/>
  <div class="container m-bot-35 m-top-25 clearfix">
    <div class="row">
       <div class="three columns m-bot-25">
         <blk:sidebar/>
       </div>
       <div class="nine columns m-bot-25">
       <blk:folder.edit[doc=dokum]/>
       </div>
    </div>
  </div>
  <static:footer/>
  <static:footscripts/>
</body>
</html>
```

In the folder binder you can access template parameters
```ruby
def bind!
  @doctype = params[:doc]
end
```
