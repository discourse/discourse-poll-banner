import Component from "@ember/component";
import { ajax } from "discourse/lib/ajax";
import PostCooked from "discourse/widgets/post-cooked";
import { action } from "@ember/object";

export default Component.extend({
  classNameBindings: ["poll-banner"],
  cooked: null,
  showPoll: false,
  postId: null,

  init() {
    this._super(...arguments);

    if (!this.currentUser) {
      return;
    }

    let topicId = settings.topic_id;
    let getLocal = localStorage.getItem("poll_" + topicId);

    if (topicId && !getLocal) {
      ajax(`/t/${topicId}.json`).then((response) => {
        let firstPost = response.post_stream.posts[0].cooked;
        let cachedTopic = new PostCooked({
          cooked: firstPost,
        });

        this.set("postId", response.post_stream.posts[0].id);
        this.set("cooked", cachedTopic.attrs.cooked);
        this.set("showPoll", true);

        document
          .querySelector(".poll-banner-connector")
          .classList.add("visible-poll");
      });
    }
  },

  click(e) {
    let voteClick = e.target.getAttribute("data-poll-option-id");

    if (voteClick) {
      let voteOptions = document.querySelectorAll("[data-poll-option-id]");

      let voteSelected = document.querySelector(
        '[data-poll-option-id="' + voteClick + '"]'
      );

      voteOptions.forEach((option) => {
        option.classList.remove("selected-vote");
      });

      voteSelected.classList.add("selected-vote");

      ajax("/polls/vote", {
        type: "PUT",
        data: {
          post_id: this.postId,
          poll_name: settings.poll_name,
          options: [voteClick],
        },
      }).then((result) => {
        if (result.vote[0].length > 0) {
          var msDelay = 1000;
          setTimeout(() => {
            this.send("closePoll");
          }, msDelay);
        }
      });
    }
  },

  @action
  closePoll() {
    localStorage.setItem("poll_" + settings.topic_id, "true");
    document
      .querySelector(".poll-banner-connector")
      .classList.remove("visible-poll");
    this.set("showPoll", false);
  },
});
