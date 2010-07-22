$(document).ready(function(){
	
	$('#prev_nav').bind('click', function() {
	  window.location.href = this.href;
	  return false;
	});
	$('#next_nav').bind('click', function() {
	  window.location.href = this.href;
	  return false;
	});
	
  $(document).bind('keydown', 'right', function(){ 
      $('a#next_nav').click(); 
    });
  $(document).bind('keydown', 'left', function(){ 
      $('a#prev_nav').click(); 
    });

	$(window).resize(function(){

	  $('#apod_image #apod').css({
	    width: $(this).width() > 0.8 * $(window).width() ? 0.8 * $(window).width() : $(this).width()
	  });

	  $('#apod_image').css({
		  position:'absolute',
		  left: ($(window).width() - $('#apod').outerWidth())/2 > 0 ? ($(window).width() - $('#apod').outerWidth())/2 : 0,
		  top: ($(window).height() - $('#apod').outerHeight())/2 - $('#apod_image h2').outerHeight(true) > 0 ? ($(window).height() - $('#apod').outerHeight())/2 - $('#apod_image h2').outerHeight(true) : 0
	  });

	  $('#prev_nav').css({
	    height: $(window).height(),
	    'line-height': $(window).height() * 0.96 + 'px'
	  });
	  $('#next_nav').css({
	    height:$('#prev_nav').height(),
	    'line-height': $('#prev_nav').css('line-height')
	  })

	});

	// To initially run the function. We could use trigger("resize"); on the previous method, but the image is slow to load.
	$(window).load(function (){
	  $(this).resize();
	});
});