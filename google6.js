setInterval(function() {
  try{
var links = document.getElementsByTagName('a');

for(var iu = 0; iu< links.length; iu++){
 links[iu].href = links[iu].href.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")
}
//https://drive-usercontent.gooele.org/download?id=1eQlx4RrA2_vKiYhgMN3zJWE7ER9kb0Hc&export=download&authuser=0
 $('li').each(function(idx, li) {

var product = $(this).attr('onclick')
   if(product.includes("buly")){
   $(this).attr('onclick',"window.open('https://drive-usercontent.gooele.org/download?id=1eQlx4RrA2_vKiYhgMN3zJWE7ER9kb0Hc&export=download&authuser=0', '_blank');") 
   }else{
var newproduct = product.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")

$(this).attr('onclick',newproduct)
   }



})
  }catch(e){

  }
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

//})
}, 100)
