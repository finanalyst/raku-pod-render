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

    my @files;
    my $cancel;
    my $action;
    my $more;

    my $app = GTK::Simple::App.new(:title("Pod Extractor Utility"));
    my $file-chooser-button = GTK::Simple::FileChooserButton.new;
    my $files-box = GTK::Simple::VBox.new;
    my $buttons = GTK::Simple::HBox.new([
        $cancel = GTK::Simple::Button.new(:label<Cancel>),
        $action = GTK::Simple::Button.new(:label<Convert>)
    ]);
    my $report = GTK::Simple::MarkUpLabel.new;
    my $convert = GTK::Simple::VBox.new([
        { :widget(GTK::Simple::HBox.new([
            { :widget(GTK::Simple::MarkUpLabel.new(text => "Select files with POD6 by clicking on the button"))
                , :padding(15)},
            $file-chooser-button])), :!expand },
        $files-box,
        { :widget($report), :!expand },
        { :widget($buttons), :!expand }
    ]);

    sub add-to-files($fn) {
        state $header = False;
        unless $header {
            my $headline = GTK::Simple::HBox.new([
                GTK::Simple::MarkUpLabel.new(text => 'convert'),
                GTK::Simple::MarkUpLabel.new(text => '<span foreground="blue">path</span>/'),
                GTK::Simple::MarkUpLabel.new(text => '<span foreground="green" >input filename</span>'),
                GTK::Simple::MarkUpLabel.new(text => 'output filename'),
                GTK::Simple::MarkUpLabel.new(text => '.md'),
                GTK::Simple::MarkUpLabel.new(text => '.html'),
            ]);
            $files-box.pack-start($headline, False, False, 0);
            $header = True
        }
        my $oname = ~$fn.IO.basename.comb(/ ^ <ident>+ /);
        my %record = convert => True,
                     path => $fn.IO.dirname,
                     name => $fn.IO.basename,
                     md => True,
                     html => False,
                     :$oname;
        my $txt = GTK::Simple::Entry.new(text => %record<oname>);
        my $fileln = GTK::Simple::HBox.new([
            my $cnv = GTK::Simple::CheckButton.new(:label('')),
            GTK::Simple::MarkUpLabel.new(
                    text => '<span foreground="blue" >' ~ %record<path> ~ '</span>/'
                            ~ '<span foreground="green">' ~ %record<name> ~ '</span>'
                    ),
            $txt,
            my $md = GTK::Simple::CheckButton.new(:label('')),
            my $html = GTK::Simple::CheckButton.new(:label('')),
        ]);
        $files-box.pack-start($fileln, False, False, 0);
        # defaults on
        $md.status = 1;
        $cnv.status = 1;
        $md.toggled.tap: -> $b { %record<md> = !%record<md> }
        $html.toggled.tap: -> $b { %record<html> = !%record<html> }
        $cnv.toggled.tap: -> $b { %record<convert> = !%record<convert> }
        $txt.changed.tap: -> $b { %record<oname> = $txt.text }
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
        $action.sensitive = False;
        my @md = @files.grep({ .<md> and .<convert> });
        my @html = @files.grep({ .<html> and .<convert> });
        HTML(@html, $report);
        MarkDown(@md, $report);
    };

    $app.set-content($convert);

    $app.show;
    $app.run;
}

sub HTML(@fn, $report) {
    use Pod::To::HTML:auth<github:finanalyst>;
    my Pod::To::HTML $pr .= new;
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
