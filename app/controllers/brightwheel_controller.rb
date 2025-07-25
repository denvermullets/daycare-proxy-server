class BrightwheelController < ApplicationController
  # Emoji mapping for action types
  EMOJIS = {
    'Checkin' => '👋',
    'Checkout' => '👋',
    'Photo' => '📸',
    'Food' => '🍽️',
    'Nap' => '😴',
    'Potty' => '🚽',
    'Milestone' => '🏆',
    'Message' => '✉️',
    'Health' => '🩺',
    'Incident' => '⚠️',
    'Note' => '📝',
    'Mood' => '😊',
    'Lesson' => '📚',
    'Observation' => '🔍',
    'Activity' => '🎨'
  }.freeze

  def activities
    base_url = ENV.fetch('BRIGHTWHEEL_URL', nil)
    student_id = ENV.fetch('STUDENT_ID', nil)
    cookie = ENV.fetch('BRIGHTWHEEL_COOKIE', nil)

    url = "#{base_url}/#{student_id}/activities?page=0&page_size=100&#{time_period}&include_parent_actions=true"

    response = HTTParty.get(url, headers: { 'Cookie' => cookie })

    render json: parse_response(response.body)
  end

  def time_period
    Time.zone = 'America/New_York'
    start_at = Time.zone.now.beginning_of_day - 1.day
    end_at = Time.zone.now.end_of_day - 1.day

    "start_date=#{start_at}&end_date=#{end_at}"
  end

  def parse_response(response)
    data = JSON.parse(response)

    entries = data['activities'].map do |activity|
      raw_type = activity['action_type'] || ''
      formatted_type = raw_type.sub(/^ac_/, '').titleize
      emoji = EMOJIS[formatted_type] || '🧸'
      time = Time.parse(activity['event_date']).in_time_zone('America/New_York').strftime('%I:%M %p')

      note = activity['note']&.gsub(/\s+/, ' ')&.strip || '(no note)' # replaces newlines and multiple spaces

      "#{time} — #{emoji} #{formatted_type}: #{note}"
    end

    entries.uniq # removes duplicates
  end
end
