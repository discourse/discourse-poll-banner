import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import KeyValueStore from "discourse/lib/key-value-store";

export default class PollBanner extends Component {
  @service currentUser;

  @tracked cooked;
  @tracked postId;
  @tracked isVisible = false;

  pollStore = new KeyValueStore("poll-banner_");

  get shouldShowPoll() {
    const topicId = settings.topic_id;
    return (
      topicId &&
      topicId !== 0 &&
      this.currentUser &&
      !this.pollStore.get(`${topicId}_closed`)
    );
  }

  getCachedPollData() {
    return this.pollStore.getObject(String(settings.topic_id));
  }

  cachePollData(cooked, postId) {
    const pollData = {
      cooked,
      postId,
      timestamp: Date.now(),
    };
    this.pollStore.setObject({
      key: String(settings.topic_id),
      value: pollData,
    });
    return pollData;
  }

  async loadPollFromTopic() {
    const topicId = settings.topic_id;
    try {
      const response = await ajax(`/t/${topicId}.json`);
      const firstPost = response.post_stream.posts[0];
      const pollData = this.cachePollData(firstPost.cooked, firstPost.id);
      this.cooked = pollData.cooked;
      this.postId = pollData.postId;
    } catch (error) {
      this.isVisible = false;
      popupAjaxError(error);
    }
  }

  loadPollFromCache(cachedData) {
    this.cooked = cachedData.cooked;
    this.postId = cachedData.postId;
    return Date.now() - cachedData.timestamp;
  }

  shouldDisplayBanner(timeElapsed) {
    const showTime = 60000 * settings.show_after;
    const stopTime = 60000 * settings.stop_after;
    return timeElapsed >= showTime && timeElapsed <= stopTime;
  }

  @action
  async setupPoll() {
    if (!this.shouldShowPoll) {
      return;
    }

    const cachedData = this.getCachedPollData();
    let timeElapsed = 0;

    if (cachedData) {
      timeElapsed = this.loadPollFromCache(cachedData);
    } else {
      await this.loadPollFromTopic();
    }

    this.isVisible = this.shouldDisplayBanner(timeElapsed);
  }

  @action
  handleVote(event) {
    const voteOptionId = event.target.getAttribute("data-poll-option-id");

    if (!voteOptionId) {
      return;
    }

    const pollContainer = event.currentTarget;
    pollContainer
      .querySelectorAll("[data-poll-option-id]")
      .forEach((option) => option.classList.remove("selected-vote"));
    event.target.classList.add("selected-vote");

    ajax("/polls/vote", {
      type: "PUT",
      data: {
        post_id: this.postId,
        poll_name: settings.poll_name,
        options: [voteOptionId],
      },
    })
      .then((result) => {
        if (result.vote[0].length > 0) {
          setTimeout(() => {
            this.closePoll();
          }, 1000);
        }
      })
      .catch(popupAjaxError);
  }

  @action
  closePoll() {
    this.pollStore.set({
      key: `${settings.topic_id}_closed`,
      value: "true",
    });
    this.isVisible = false;
  }

  <template>
    <div
      class="above-main-container-outlet poll-banner-connector
        {{if this.isVisible 'visible-poll'}}"
      {{didInsert this.setupPoll}}
    >
      {{! template-lint-disable no-invalid-interactive }}
      <div
        class="poll-banner poll-banner-content"
        {{on "click" this.handleVote}}
      >
        {{htmlSafe this.cooked}}
        <DButton
          class="btn-flat"
          @action={{this.closePoll}}
          @icon="xmark"
          @label="share.close"
        />
        <div class="poll-banner-key">{{settings.poll_key}}</div>
      </div>
    </div>
  </template>
}
