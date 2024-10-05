setInterval(function() {

if($('.dwonle > ul > li').length > 1) {
$('.dwonle > ul > li').each(function(idx, li) {
var product = $(this).attr('onclick')
var newproduct = product.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")

console.log(newproduct)
$(this).attr('onclick',newproduct)
})

}
}, 100)
