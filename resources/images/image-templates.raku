%(
    image => sub (%prm, %tml) {
        '<div class="image-container '
        ~ ( %prm<class> // '' )
        ~ '"><img src="' ~ ( %prm<src> // 'path/to/image' ) ~  '"'
        ~ ' width="' ~ (%prm<width> // '100px') ~ '"'
        ~ ' height="' ~ (%prm<height> // 'auto') ~ '"'
        ~ ' alt="' ~ (%prm<alt> // 'No caption') ~ '"'
        ~ ( %prm<id>:exists ?? (' id="' ~ %prm<id>  ~ '"') !! '' )
        ~ ">\</div>\n"
    },
)