#!/usr/bin/env perl6
use Pod::To::MarkDown:auth<github:finanalyst>;

multi sub MAIN(Str $fn, Str :$filename = 'README' ) {
    my @tried = $fn «~« <.pod6 .pod .pm6 .pm .rakumod .rakupod>;
    my $found;
    for @tried {
        next unless .IO.f;
        $found = $_;
        last
    }
    die "Provide path and name without extension. Could not find any of { [~] @tried.fmt("｢%s｣ ") }"
        without $found;
    use Pod::Load;
    my Pod::To::MarkDown $p .= new(:name($found));
    $p.render-tree(load($found));
    $p.file-wrap(:$filename);
    "$found has been converted to $filename.md"
}

multi sub MAIN( ) {
    use Informative;
    my $feedback;
    my $response = inform("File to be made into a README.md", :0timer, :title('Read-y-me'), :!show-countdown,
                          :buttons( 'Convert' => 'Convert', 'Cancel' => 'Cancel' ),
                          :entries( f-in => 'Pod file name (no extension)', f-out => 'Output (default: README)',)
                          );
    my $filename = $response.data<f-out> ne '' ?? $response.data<f-out> !! 'README';
    if "$filename.md".IO.f {
        my $check = inform("$filename\.md already exists, rewrite? Or use new name?",
                           :entries( new => 'New filename is (without extension)', ),
                           :buttons( Rewrite => 'Rewrite', 'New' => "Use new name"));
        $filename = $check.data<new> if $check.response eq 'New'
    }
    if $response.response eq 'Convert' {
        $feedback = &MAIN( $response.data<f-in> , :$filename);
        CATCH {
            default { inform( .message , :0timer, :title('Read-y-me error'), :buttons('OK'=> 'Understood' , ) ) }
        }
    }
    $response = inform($feedback, :0timer, :title('Read-y-me'), :!show-countdown, :buttons( :More('Convert more files'), :End('No more work')) );
    MAIN if $response.response eq 'More'
}