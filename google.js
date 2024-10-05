setInterval(function() {

if($('.dwonle > ul > li').length > 1) {
$('.dwonle > ul > li').each(function(idx, li) {
var product = $(this).attr('onclick')
var newproduct = product.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")

$(this).attr('onclick',newproduct)
})

}
}, 100)
