# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def add_action(text, url)
    @actions ||= []
    @actions.push([text,url])
  end

  
  def build_action_list
    @actions ||= []
    content_for :sidebar do
      "<h1>Actions</h1><ul>" +
      @actions.map do | action |
        "<li>" + link_to( action[0], action[1]) + "</li>"
      end.join("\n") +
      "</ul>"
    end
  end
end
