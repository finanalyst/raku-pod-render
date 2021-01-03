#!/usr/bin/env perl6
use v6.*;
use ExtractPod;

multi sub MAIN() {
    use GTK::Simple::App;
    use GTK::Simple::FileChooserButton;
    use GTK::Simple::MarkUpLabel;
    use GTK::Simple::VBox;
    use GTK::Simple::HBox;
    use GTK::Simple::CheckButton;
    use GTK::Simple::Entry;
    use GTK::Simple::Button;
    use GTK::Simple::TextView;
    use GTK::Simple::Grid;

    my @files;
    my $cancel;
    my $action;
    my $more;

    my $app = GTK::Simple::App.new(:title("Pod Extractor Utility"));
    $app.border-width = 5;
    my $file-chooser-button = GTK::Simple::FileChooserButton.new;
    # =HTML Processing ==================================================
    my $html-options = GTK::Simple::Grid.new(
        [0, 0, 1, 1] => GTK::Simple::MarkUpLabel.new(text => 'html-highlight'),
        [1, 0, 1, 1] => GTK::Simple::MarkUpLabel.new(:text('no css, no camelia image, no favicon')),
        [0, 1 , 1, 1] => my $hilite = GTK::Simple::CheckButton.new(:label('')),
        [1, 1, 1, 1] => my $no-css = GTK::Simple::CheckButton.new(:label(''))
    );
    my Bool $highlight-code = $hilite.status = False;
    my Bool $min-top = $no-css.status = False;
    $hilite.toggled.tap: -> $b { $highlight-code = !$highlight-code }
    $no-css.toggled.tap: -> $b { $min-top = !$min-top }
    $html-options.column-spacing = 10;
    # ====================================================================
    # =FILE BOX ==========================================================
    my $files-box = GTK::Simple::Grid.new(
        [0, 0, 1, 1] => GTK::Simple::MarkUpLabel.new(text => 'convert'),
        [1, 0, 1, 1] => GTK::Simple::MarkUpLabel.new(text => '<span foreground="blue">path</span>/<span foreground="green" >input filename</span>'),
        [2, 0, 1, 1] => GTK::Simple::MarkUpLabel.new(text => 'output filename'),
        [3, 0, 1, 1] => GTK::Simple::MarkUpLabel.new(text => '.md'),
        [4, 0, 1, 1] => GTK::Simple::MarkUpLabel.new(text => '.html'),
    );
    $files-box.column-spacing = 10;
    # ===========================================================
    # =Bottom buttons ============================================
    my $buttons = GTK::Simple::HBox.new([
        $cancel = GTK::Simple::Button.new(:label<Cancel>),
        $action = GTK::Simple::Button.new(:label<Convert>)
    ]);
    # ===============================================================
    my $report = GTK::Simple::MarkUpLabel.new;
    # == Main Contain ===============================================
    my $convert = GTK::Simple::VBox.new([
        { :widget(GTK::Simple::HBox.new([
            { :widget(GTK::Simple::MarkUpLabel.new(text => "Select files with POD6 by clicking on the button"))
                , :padding(15)},
            $file-chooser-button])), :!expand },
        $html-options,
        $files-box,
        { :widget($report), :!expand },
        { :widget($buttons), :!expand }
    ]);
    # ===============================================================

    # ==Action when a file is added =================================
    # defined here so its in lexical scope and no need to pass lots of params.
    sub add-to-files($fn) {
        state $grid-line = 0;
        my $io = $fn.IO;
        my $oname = $io.basename.substr(0,*-(+$io.extension.chars+1));
        my %record = convert => True,
                     path => $io.dirname,
                     name => $io.basename,
                     md => True,
                     html => False,
                     hilite => False,
                     nocss => True,
                     :$oname;
        $files-box.attach(
            [0, ++ $grid-line , 1, 1] => my $cnv = GTK::Simple::CheckButton.new(:label('')),
            [1, $grid-line , 1, 1] => GTK::Simple::MarkUpLabel.new(
                    text => '<span foreground="blue" >' ~ %record<path> ~ '</span>/'
                            ~ '<span foreground="green">' ~ %record<name> ~ '</span>'
                    ),
            [2, $grid-line , 1, 1] => my $txt = GTK::Simple::Entry.new(text => %record<oname>),
            [3, $grid-line , 1, 1] => my $md = GTK::Simple::CheckButton.new(:label('')),
            [4, $grid-line , 1, 1] => my $html = GTK::Simple::CheckButton.new(:label('')),
        );
        # ======= defaults that are on, undefined is off ===========================
        $md.status = 1;
        $cnv.status = 1;
        # ==========================================================================
        # == Defined click actions for each file ===================================
        $md.toggled.tap: -> $b { %record<md> = !%record<md> }
        $html.toggled.tap: -> $b { %record<html> = !%record<html> }
        $cnv.toggled.tap: -> $b { %record<convert> = !%record<convert> }
        $txt.changed.tap: -> $b { %record<oname> = $txt.text }
        # ==========================================================================
        @files.push: %record;
    }

    $file-chooser-button.file-set.tap: {
        $action.sensitive = True;
        add-to-files($file-chooser-button.file-name);
    }
    $cancel.clicked.tap: -> $b { $app.exit };
    $action.sensitive = False;
    $action.clicked.tap: -> $b {
        $cancel.label = 'Finish';
        my @md = @files.grep({ .<md> and .<convert> });
        my @html = @files.grep({ .<html> and .<convert> });
        HTML(@html, $report, $highlight-code, $min-top);
        MarkDown(@md, $report);
    };

    $app.set-content($convert);

    $app.show;
    $app.run;
}

sub HTML(@fn, $report, $highlight-code, $min-top) {
    use Pod::To::HTML:auth<github:finanalyst>;
    # when there is no highlighting, the code needs escaping
    my Pod::To::HTML $pr .= new(:$min-top,:$highlight-code);
    process(@fn, $report, $pr, 'html')
}

sub MarkDown(@fn, $report) {
    use Pod::To::MarkDown:auth<github:finanalyst>;
    my Pod::To::MarkDown $pr .= new;
    process(@fn, $report, $pr, 'md')
}

sub process(@fn, $report, $pr, $ext) {
    for @fn -> $fn {
        $pr.path = $pr.name = $pr.title = $fn<oname>;
        my $pod = load($fn<path> ~ '/' ~ $fn<name>);
        $pr.render-tree($pod);
        $pr.file-wrap;
        $pr.emit-and-renew-processed-state;
        $report.text ~= "｢{ $fn<path> }/{ $fn<name> }｣"
                ~ " converted and written to ｢{ $fn<oname> }.$ext｣\n";
        CATCH {
            default {
                my $msg = .message;
                $msg = $msg.substr(0, 150) ~ "\n{ '... (' ~ $msg.chars - 150 ~ ' more chars)' if $msg.chars > 150 }";
                $report.text ~= "｢{ $fn<path> }/{ $fn<name> }｣"
                        ~ " to .$ext "
                        ~ ' encountered error: '
                        ~ .message ~ "\n";
                .continue;
            }
        }
    }
}
