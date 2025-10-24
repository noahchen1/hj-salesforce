trigger CampaignMemberTrigger on CampaignMember (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        CampaignMemberService.onAfterInsert(Trigger.new);
    }
}

