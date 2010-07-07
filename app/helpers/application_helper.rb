# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def add_action(text, url)
    @actions ||= []
    @actions.push([text,url])
  end

  def display_online(item)
    item.online? ? "<span class='online'>Online</span>" : "<span class='offline'>Offline</span>"
  end
  
  def build_action_list
    @actions ||= []
    if @actions.size > 0
      content_for :sidebar do
        '<ul>' +
        @actions.map do | action |
          "<li>" + link_to( action[0], action[1]) + "</li>"
        end.join("\n") + '</ul>'
      end
    end
  end
  
  def selected_tab?(cont)
    @controller.controller_name == cont ? 'active' : 'inactive'
  end
  
  def display_backup_duration(job)
    return 'Unknown' unless job
    return 'Not yet started' if job.status == 'queued'
    start_time = job.started || job.created_at
    end_time = job.updated_at
    
    if job.status == 'running'
      start_time = job.updated_at
      end_time = Time.new
    end
      
    distance_of_time_in_words(start_time, end_time )
  end
end
