# frozen_string_literal: true

RSpec.describe "Poll Banner", type: :system do
  let!(:theme) { upload_theme_component }
  fab!(:user)
  fab!(:topic_with_poll) do
    topic = Fabricate(:topic)
    raw_content = <<~MD
      # How likely are you to recommend us?

      [poll name=nps type=number results=always min=0 max=10 step=1]
      [/poll]
    MD
    post = Fabricate(:post, topic: topic, raw: raw_content)
    post.rebake!
    topic
  end

  def dismiss_modals
    if page.has_css?(".dialog-overlay", wait: 0)
      page.execute_script("document.querySelector('.dialog-overlay')?.click()")
    end
  end

  context "when topic_id is set to 0" do
    before do
      sign_in(user)
      theme.update_setting(:topic_id, 0)
      theme.save!
    end

    it "does not display the banner" do
      visit("/")
      expect(page).to have_no_css(".poll-banner-connector.visible-poll")
    end
  end

  context "when topic_id is configured" do
    before { sign_in(user) }
    before do
      theme.update_setting(:topic_id, topic_with_poll.id)
      theme.update_setting(:show_after, 0) 
      theme.update_setting(:stop_after, 10080)
      theme.save!
    end

    it "displays the poll banner for logged in users" do
      visit("/")
      expect(page).to have_css(".poll-banner-connector.visible-poll")
      expect(page).to have_css(".poll-banner-content")
    end

    it "displays the close button" do
      visit("/")
      expect(page).to have_css(".poll-banner-content .btn-flat")
    end

    it "hides the banner when close button is clicked" do
      visit("/")
      expect(page).to have_css(".poll-banner-connector.visible-poll")

      dismiss_modals
      find(".poll-banner-content .btn-flat").click

      expect(page).to have_no_css(".poll-banner-connector.visible-poll")
    end

    it "remembers when banner is closed and does not show it again" do
      visit("/")
      expect(page).to have_css(".poll-banner-connector.visible-poll")

      dismiss_modals
      find(".poll-banner-content .btn-flat").click
      expect(page).to have_no_css(".poll-banner-connector.visible-poll")

      visit("/about")
      visit("/")

      expect(page).to have_no_css(".poll-banner-connector.visible-poll")
    end

  end

  context "when user is not logged in" do
    before do
      theme.update_setting(:topic_id, topic_with_poll.id)
      theme.update_setting(:show_after, 0)
      theme.save!
    end

    it "does not display the banner" do
      visit("/")
      expect(page).to have_no_css(".poll-banner-connector.visible-poll")
    end
  end

  context "with show_after timing" do
    before do
      sign_in(user)
      theme.update_setting(:topic_id, topic_with_poll.id)
      theme.update_setting(:show_after, 1)
      theme.update_setting(:stop_after, 10080)
      theme.save!
    end

    it "does not show banner immediately on first visit" do
      visit("/")
      expect(page).to have_no_css(".poll-banner-connector.visible-poll")
    end
  end
end
