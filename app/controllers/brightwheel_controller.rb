class BrightwheelController < ApplicationController
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
    start_at = Time.zone.now.beginning_of_day
    end_at = Time.zone.now.end_of_day

    "start_date=#{start_at}&end_date=#{end_at}"
  end

  def parse_response(response)
    data = JSON.parse(response)

    data['activities'].map do |activity|
      format_activity_entry(activity)
    end.uniq
  end

  private

  def format_activity_entry(activity)
    raw_type = activity['action_type'] || ''
    formatted_type = format_type(raw_type)
    time = format_time(activity['event_date'])
    # emoji = EMOJIS[formatted_type] || '🧸'
    note = extract_note(activity)

    # "[#{time}] #{emoji} #{formatted_type}: #{note}"
    "[#{time}] #{formatted_type}: #{note}"
  end

  def format_type(raw_type)
    raw_type.sub(/^ac_/, '').titleize
  end

  def format_time(timestamp)
    Time.parse(timestamp).in_time_zone('America/New_York').strftime('%I:%M %p')
  end

  def extract_note(activity)
    return potty_note(activity['details_blob'], activity['note']) if activity['action_type'] == 'ac_potty'

    cleaned_note(activity['note']) || '(no note)'
  end

  def potty_note(details_blob, note)
    return '(no potty details)' unless details_blob

    type = details_blob['potty_type'] || 'unknown'
    status = details_blob['potty'] || 'unknown'
    extras = Array(details_blob['potty_extras']).join(', ')

    summary = "Type: #{type}, Status: #{status}"
    summary += ", Extras: #{extras}" unless extras.empty?

    note_part = cleaned_note(note)
    note_part ? "#{summary}. Note: #{note_part}" : summary
  end

  def cleaned_note(note)
    note&.gsub(/\s+/, ' ')&.strip
  end
end
