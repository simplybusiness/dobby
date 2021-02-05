FROM ruby:3.0.0-slim

LABEL maintainer="simplybusiness <opensourcetech@simplybusiness.co.uk>"

RUN gem install bundler

RUN mkdir -p /runner/action

WORKDIR /runner/action

COPY Gemfile* ./

RUN bundle install --retry 3

COPY lib ./lib

COPY run.rb ./

ENV BUNDLE_GEMFILE /runner/action/Gemfile

RUN chmod +x /runner/action/run.rb

CMD ["ruby", "/runner/action/run.rb"]
