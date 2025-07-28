import Component from "@ember/component";
import { action } from "@ember/object";
import { classNameBindings } from "@ember-decorators/component";
import DButton from "discourse/components/d-button";
import htmlSafe from "discourse/helpers/html-safe";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

@classNameBindings("poll-banner")
export default class PollBanner extends Component {
  cooked = null;
  showPoll = false;
  postId = null;

  init() {
    super.init(...arguments);

    if (
      !this.currentUser ||
      localStorage.getItem(`polls_${settings.topic_id}_closed`)
    ) {
      return;
    }

    const date = Date.now();
    let topicId = settings.topic_id;
    let getLocal = localStorage.getItem("polls_" + topicId);
    let showTime = 60000 * settings.show_after;
    let stopTime = 60000 * settings.stop_after;
    let timeElapsed = 0;

    if (topicId && !getLocal) {
      ajax(`/t/${topicId}.json`).then((response) => {
        let firstPost = response.post_stream.posts[0].cooked;
        let cachedTopic = {
          attrs: {
            cooked: firstPost,
            postId: response.post_stream.posts[0].id,
            timestamp: date,
          },
        };

        localStorage.setItem(
          "polls_" + settings.topic_id,
          JSON.stringify(cachedTopic)
        );
        this.set("postId", cachedTopic.attrs.postId);
        this.set("cooked", cachedTopic.attrs.cooked);
      });
    } else if (topicId && getLocal) {
      let storage = JSON.parse(
        localStorage.getItem("polls_" + settings.topic_id)
      );
      timeElapsed = date - storage.attrs.timestamp;
      this.set("cooked", storage.attrs.cooked);
      this.set("postId", storage.attrs.postId);
    }

    if (timeElapsed >= showTime && timeElapsed <= stopTime) {
      this.set("showPoll", true);
      document
        .querySelector(".poll-banner-connector")
        .classList.add("visible-poll");
    } else {
      this.set("showPoll", false);
      document
        .querySelector(".poll-banner-connector")
        .classList.remove("visible-poll");
    }
  }

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
      })
        .then((result) => {
          if (result.vote[0].length > 0) {
            let msDelay = 1000;
            setTimeout(() => {
              this.send("closePoll");
            }, msDelay);
          }
        })
        .catch(popupAjaxError);
    }
  }

  @action
  closePoll() {
    localStorage.setItem(`polls_${settings.topic_id}_closed`, "true");
    document
      .querySelector(".poll-banner-connector")
      .classList.remove("visible-poll");
    this.set("showPoll", false);
  }

  <template>
    <div class="poll-banner-content">
      {{htmlSafe this.cooked}}
      <DButton
        class="btn-flat"
        @action={{action "closePoll"}}
        @icon="times"
        @label="share.close"
      />
      <div class="poll-banner-key">{{settings.poll_key}}</div>
    </div>
  </template>
}
