import Component from "@ember/component";
import { classNames } from "@ember-decorators/component";
import PollBanner from "../../components/poll-banner";

@classNames("above-main-container-outlet", "poll-banner-connector")
export default class PollBannerConnector extends Component {
  <template>
    {{#if this.currentUser}}
      <PollBanner />
    {{/if}}
  </template>
}
