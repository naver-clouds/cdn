setInterval(function() {
  
if($('.dwonle > ul > li').length > 1) {
$('.dwonle > ul > li').each(function(idx, li) {
    var product = $(this).find("a").attr('href')
    var newproduct = product.replace("drive.usercontent.google.com","drive-usercontent.gooele.org")
    $(this).find("a").attr('href',newproduct)
  })
    
}
}, 100)
