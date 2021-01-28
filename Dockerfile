FROM ruby:2.6.6

RUN apt-get update && apt-get install -y libpq-dev

WORKDIR /app

COPY Gemfile .
COPY Gemfile.lock .

RUN gem install bundler
RUN bundle install

COPY . .

CMD ["rackup", "-o", "0.0.0.0", "-p", "3000", "config.ru"]
