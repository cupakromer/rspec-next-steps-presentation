use Rack::Static,
  urls: %w[/images /js /css /md],
  root: 'public'

run lambda { |env|
  [
    200,
    {
      'Content-Type' => 'text/html',
      'Cache-Control' => 'public, max-age=86400'
    },
    File.open('public/Presenter.html', File::RDONLY)
  ]
}
