FROM ruby:3.2-alpine
WORKDIR /app
COPY src/Gemfile .
RUN bundle install
COPY src/ .
EXPOSE 3000
CMD ["ruby", "server.rb"]
