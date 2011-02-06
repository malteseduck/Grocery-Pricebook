xquery version "1.0-ml";

declare namespace xh="http://www.w3.org/1999/xhtml";
declare namespace lists = "http://malteseduck/lists/v1";
declare namespace s = "http://www.w3.org/2009/xpath-functions/analyze-string";

let $lists := (
  "http://www.grocerysmarts.com/utah/lists/indexg84gen.php?m84ac2",
  "http://www.grocerysmarts.com/utah/lists/indexg84gen.php?s84un2",
  "http://www.grocerysmarts.com/utah/lists/indexg84gen.php?h84ar2",
  "http://www.grocerysmarts.com/utah/lists/indexg84gen.php?m84ac2",
  "http://www.grocerysmarts.com/utah/lists/indexg84gen.php?a84sl2",
  "http://www.grocerysmarts.com/utah/lists/indexg84gen.php?r84ea2"
)

let $stores := (
  "Smith's",
  "Fresh Market",
  "Harmons",
  "Maceys",
  "Associated Foods",
  "Reams"
)

let $items :=
 for $uri at $index in $lists
 return
 for $item in  
        xdmp:tidy(
            xdmp:http-get($uri)[2]
        )[2]//xh:tr[@bgcolor eq "#D8D8D8"]
    let $rating := fn:normalize-space(xs:string($item/xh:td[1]))
    let $name := fn:normalize-space(xs:string($item/xh:td[2]))
    let $salePriceString := fn:normalize-space(xs:string($item/xh:td[3]))
    let $salePrice := fn:data(fn:analyze-string($salePriceString , "[0-9]*\.[0-9]+")//s:match)[1]
    let $salePriceUnit := fn:data(fn:analyze-string($salePriceString, "[a-z]+")//s:match)[1]
    let $coupon := fn:normalize-space(xs:string($item/xh:td[4]))
    let $priceString := fn:normalize-space(xs:string($item/xh:td[5]))
    let $price := fn:data(fn:analyze-string($priceString , "[0-9]*\.[0-9]+")//s:match)[1]
    let $priceUnit := fn:data(fn:analyze-string($priceString, "[a-z]+")//s:match)[1]
    let $debug := xdmp:log(fn:concat("############ item name: ", $name))
    let $productId := xdmp:hash64(fn:replace(fn:lower-case($name), " ", ""))
    let $id := xdmp:hash64($name)
    let $debug := xdmp:log(fn:concat("## product id: ", $productId))
    let $debug := xdmp:log(fn:concat("## item id: ", $id))
    let $debug := xdmp:log(fn:concat("## item exists: ", fn:exists(/lists:item[@id eq $id]/fn:base-uri())))
    let $xml :=
        <item id="{ $id }" productId="{ $productId }" xmlns="http://malteseduck/lists/v1">
            <store>{ $stores[$index] }</store>
            <rating>{ $rating }</rating>
            <name>{ $name }</name>
            <sale-price>{ $salePrice }</sale-price>
            <sale-price-unit>{ $salePriceUnit }</sale-price-unit>
            <coupon>{ $coupon }</coupon>
            <price>{ $price }</price>
            <price-unit>{ $priceUnit }</price-unit>
        </item>
    where $price ne ""
    return 
        $xml

return
<table width="100%" border="1">
  <tr valign="top">
    <td>*</td>
    <td>ID</td>
    <td>Name</td>
    <td>Sale Price</td>
    <td>Price</td>
    <td style="white-space:nowrap;">Store</td>
    <td>Coupons</td>
  </tr>
{
  for $item in $items
  order by $item/lists:name
  return
    <tr valign="top">
      <td>{ $item/lists:rating/text() }</td>
      <td>{ fn:data($item/@productId) }</td>
      <td>{ $item/lists:name/text() }</td>
      <td>{ $item/lists:sale-price/text() }</td>
      <td>{ $item/lists:price/text() }</td>
      <td style="white-space:nowrap;">{ $item/lists:store/text() }</td>
      <td>{ $item/lists:coupon/text() }</td>
    </tr>
}
</table>