use v6.*;

class X::ProcessedPod::MissingTemplates is Exception {
    has @.missing;
    method message() {
        "The following templates should be supplied, but are not:\n"
        ~ ( @.missing.elems > 5
            ?? @.missing[^5].join("\n") ~ "\n(more keys missing, not listed)"
            !! @.missing.join("\n")
        )
    }
}

class X::ProcessedPod::Non-Existent-Template is Exception {
    has $.key;
    method message() { "Cannot process non-existent template ｢$.key｣" }
}

class X::ProcessedPod::Unexpected-Nil is Exception {
    method message() { "Unexpected handle with Nil value enountered" }
}

class X::ProcessedPod::TemplateFailure is Exception {
    has $.error;
    method message() { "Problems getting templates: $!error" }

}