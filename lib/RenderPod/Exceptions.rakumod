use v6.*;

class X::ProcessedPod::TemplateEngineMissing is Exception {
    method message {
        'A templating engine could not be detected from the templates given'
    }
}

class X::ProcessedPod::MissingTemplates is Exception {
    has @.missing;
    method message() {
        if +@.missing { "The following templates should be supplied, but are not:\n"
                ~ (@.missing.elems > 5
                        ?? @.missing[^5].join("\n") ~ "\n(more keys missing, not listed)"
                        !! @.missing.join("\n")
                )
        }
        else { "No templates loaded, ProcessedPod object method \.templates not called" }
    }
}
class X::ProcessedPod::Non-Existent-Template is Exception {
    has $.key;
    has %.params;
    multi method message() {
        "Stopping processing because non-existent template ｢$.key｣ encountered with the following parameters:\n"
                ~ %.params.gist
                ~ "\nHave you provided a custom block without a custom template?"
    }
}
class X::ProcessedPod::Unexpected-Nil is Exception {
    multi method message() {
        "Unexpected handle with Nil value enountered"
    }
}
class X::ProcessedPod::TemplateFailure is Exception {
    has $.error;
    multi method message() {
        "Problems getting templates: $!error"
    }
}
class X::ProcessedPod::NoTemplateEngine is Exception {
    multi method message() {
        "No Template engine was loaded. Is the template verification check working? Is the correct class instantiated?"
    }
}
class X::ProcessedPod::NoBlocksAdded is Exception {
    has $!filename;
    has $!path;
    multi method message() {
        "No blocks were added from ｢$!path｣/｢$!filename｣. Set filename to '' in add-custom or add-plugin if no blocks needed."
    }
}
class X::ProcessedPod::NamespaceConflict is Exception {
    has $.name-space;
    method message {
        "An attempt has been made to overwrite {$.name-space}, which is an existing name-space"
    }
}

class X::RenderPod::NoHighlightPath is Exception {
    method message { q:to/MESSAGE/ }
        No highlight path is available. Have you set up highlighter,
        eg. the atom highlighter? See Pod::To::HTML2 Installation documentation.
        MESSAGE
}
class X::RenderPod::NoAtomHighlighter is Exception {
    method message { q:to/MSG/ }
        Atom highlighter as been selected, but requisite packages not found in defined path
        MSG
}