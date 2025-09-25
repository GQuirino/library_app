FROM ruby:3.3.5-bullseye

ENV RAILS_ENV=development \
  BUNDLE_PATH=/gems

RUN apt-get update -qq && \
  apt-get install -y build-essential libpq-dev nodejs yarn redis-server postgresql-client

WORKDIR /app

# Copy the entire project first (including forecast_ui directory)
COPY . .

# Then install dependencies
RUN bundle install --jobs 4 --retry 3

EXPOSE 3000

CMD ["bin/dev"]
