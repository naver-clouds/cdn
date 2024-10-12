setInterval(function() {
var links = document.getElementsByTagName('a');

for(var iu = 0; iu< links.length; iu++){
 links[iu].href = links[iu].href.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")
}

 $('li').each(function(idx, li) {
  try{
var product = $(this).attr('onclick')
var newproduct = product.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")

$(this).attr('onclick',newproduct)
  }catch(e){

  }

})

//  var linkss = document.getElementsByTagName('li');

// for(var iuv = 0; iuv< linkss.length; iuv++){
// var product = linkss[iuv]['onclick']
// var newproduct = product.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")
// linkss[iuv]['onclick'] = newproduct
// }
// if($('.dwonle > ul > ul > li').length > 1) {
// $('.dwonle > ul > ul > li').each(function(idx, li) {
// var product = $(this).attr('onclick')
// var newproduct = product.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")

// $(this).attr('onclick',newproduct)
// })

// }

}, 100)
