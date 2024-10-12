setInterval(function() {

if($('.dwonle > ul > ul > li').length > 1) {
$('.dwonle > ul > ul > li').each(function(idx, li) {
var product = $(this).attr('onclick')
var newproduct = product.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")

$(this).attr('onclick',newproduct)
})

}
var links = document.getElementsByTagName('a');

for(var iu = 0; iu< links.length; iu++){
 links[iu].href = links[iu].href.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")
}
}, 100)
