FROM ruby:3.2-alpine

RUN apk add --no-cache build-base postgresql-dev mariadb-connector-c-dev freetds-dev sqlite-dev

WORKDIR /app
COPY src/Gemfile .
RUN bundle install
COPY src/ .

EXPOSE 3000
CMD ["sh", "-c", "rails server -b 0.0.0.0 -p 3000"]