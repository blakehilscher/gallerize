(function () {
    $(document).ready(function () {
        if ($(window).width() >= 800) {
            $('.fancybox').fancybox();
        }
        else {
            $('.image-link').each(function () {
                var image = $(this);
                var original = image.data('original');
                image.attr('href', original);
                image.attr('target', 'blank')
            });
        }
    });
})();