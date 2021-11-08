# SpanishDict Alfred Workflow

## translate.rb

translate.rb provides an interface for retrieving suggestions from spanishdict. These can be then fed into an Alfred action to open the resulting webpage.

## conjugate.rb

conjugate.rb is slightly smarter, and filters the results of the suggestions by if the resulting conjugation page exists.

As such, it is much slower than translate.rb as it's making web requests for every result (minus results with spaces in them as a rudimentary filter against sentence results).

## caching

Both scripts implement a pretty dumb cache that expires after a week.
