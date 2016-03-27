# Tzispa Rig

A general purpose template engine

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

Template variables are specified with: <var:name/>
And metavariables with: {%name%}, metavariables are used to make runtime template tags replacements

```html
<fieldset>
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
....

```

and in the template binder

```ruby
def bind!
  @idb = context.router_params[:id0]
  load_brand if idb
end

private

attr_reader :idb

def load_brand
  context.repository.use :ecomm_shop
  brand = context.repository[:brand][idb]
  data(
    idb: brand.id,
    name: brand.name,
    skey: brand.skey,
    long_name: brand.long_name,
    web: brand.web,
    manual_order: brand.manual_order,
    notes: brand.notes
  )
end
```


### Conditionals

You can make decisions in your templates using conditionals:

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
  idb = context.router_params[:id0]
  context.repository.use :ecomm_shop
  brand = context.repository[:brand][idb]
  data.customer_exist = !brand.nil?
end
```



## Repeating

To repeat a part in the template

```html
<loop:lbrands>
<tr>
  <td><var:id/></td>
  <td><var:skey/></td>
  <td><var:name/></td>
  <td class='text-right'>
    <a href='<purl:site[layout=brand_edit,title=edit-brand,id0={%id%}]/>'><i class='fa fa-edit'></i></a>
    <a href='javascript:delete_brand("<api:brand:delete:{%id%}/>")'><i class='fa fa-trash'></i></a>
  </td>
<tr>
</loop:lbrands>
```

In the binder you must use 'loop_binder'

```ruby

def bind!
  data.lbrands = loop_binder(:lbrands).bind!(&load_brands)
end

private

def load_brands
  Proc.new {
    context.repository.use :ecomm_shop
    context.repository[:brand].list.map { |b|
      loop_item(
        id: b.id,
        skey: b.skey,
        name: b.name
      )
    }
  }
end


```

## Building urls

Rig templates can build urls for you. There are 2 url types:

### purl

Site urls: used to provide links to site pages

<purl:route_id/>
<purl:route_id[param1=value,param2=value]/>

```html
<purl:site[layout=brands,title=brand-list]/>
<purl:index/>
```
The route_id's area defined in the start.ru file

### api

Api urls: used to provide urls to the application Api

<api:handler:verb/>
<api:handler:verb:predicate/>

```html
<api:customer:add:address/>

<api:brand:{%verb%}/>
```
