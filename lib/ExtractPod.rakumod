use v6.*;
use nqp;
use File::Temp;

unit module ExtractPod;

class X::ExtractPod::SourceErrors is Exception {
    has $.error;
    method message { $!error }
}
class X::ExtractPod::NoSuchSource is Exception {
    has $.fn;
    method message { "The file ｢$!fn｣ does not exist" }
}

sub load(Str $io) is export {
    X::ExtractPod::NoSuchSource.new(:$io).throw
        unless $io.IO.f;
    my $cache-path = tempdir;
    my $precomp-repo = CompUnit::PrecompilationRepository::Default.new(
            :store(CompUnit::PrecompilationStore::File.new(:prefix($cache-path.IO))),
            );
    my $handle = $precomp-repo.try-load(
            CompUnit::PrecompilationDependency::File.new(
                    :src($io),
                    :id(CompUnit::PrecompilationId.new-from-string($io)),
                    :spec(CompUnit::DependencySpecification.new(:short-name($io))),
                    )
            );
    CATCH {
        when X::ExtractPod::NoSuchSource { .rethrow }
        default {
            X::ExtractPod::SourceErrors.new(:error( .message.Str )).throw
        }
    }
    nqp::atkey($handle.unit, '$=pod')
}