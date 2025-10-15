import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import PollBanner from "../../components/poll-banner";

export default class PollBannerConnector extends Component {
  @service currentUser;

  <template>
    {{#if this.currentUser}}
      <PollBanner />
    {{/if}}
  </template>
}
