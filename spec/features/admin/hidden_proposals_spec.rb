require "rails_helper"

describe "Admin hidden proposals" do
  before do
    admin = create(:administrator)
    login_as(admin.user)
  end

  scenario "Disabled with a feature flag" do
    Setting["process.proposals"] = nil
    admin = create(:administrator)
    login_as(admin.user)

    expect { visit admin_hidden_proposals_path }.to raise_exception(FeatureFlags::FeatureDisabled)
  end

  scenario "List shows all relevant info" do
    proposal = create(:proposal, :hidden)
    visit admin_hidden_proposals_path

    expect(page).to have_content(proposal.title)
    expect(page).to have_content(proposal.summary)
    expect(page).to have_content(proposal.description)
    expect(page).to have_content(proposal.video_url)
  end

  scenario "Restore" do
    proposal = create(:proposal, :hidden)
    visit admin_hidden_proposals_path

    click_link "Restore"

    expect(page).not_to have_content(proposal.title)

    expect(proposal.reload).not_to be_hidden
    expect(proposal).to be_ignored_flag
  end

  scenario "Confirm hide" do
    proposal = create(:proposal, :hidden)
    visit admin_hidden_proposals_path

    click_link "Confirm moderation"

    expect(page).not_to have_content(proposal.title)
    click_link("Confirmed")
    expect(page).to have_content(proposal.title)

    expect(proposal.reload).to be_confirmed_hide
  end

  scenario "Current filter is properly highlighted" do
    visit admin_hidden_proposals_path
    expect(page).not_to have_link("Pending")
    expect(page).to have_link("All")
    expect(page).to have_link("Confirmed")

    visit admin_hidden_proposals_path(filter: "Pending")
    expect(page).not_to have_link("Pending")
    expect(page).to have_link("All")
    expect(page).to have_link("Confirmed")

    visit admin_hidden_proposals_path(filter: "all")
    expect(page).to have_link("Pending")
    expect(page).not_to have_link("All")
    expect(page).to have_link("Confirmed")

    visit admin_hidden_proposals_path(filter: "with_confirmed_hide")
    expect(page).to have_link("All")
    expect(page).to have_link("Pending")
    expect(page).not_to have_link("Confirmed")
  end

  scenario "Filtering proposals" do
    create(:proposal, :hidden, title: "Unconfirmed proposal")
    create(:proposal, :hidden, :with_confirmed_hide, title: "Confirmed proposal")

    visit admin_hidden_proposals_path(filter: "pending")
    expect(page).to have_content("Unconfirmed proposal")
    expect(page).not_to have_content("Confirmed proposal")

    visit admin_hidden_proposals_path(filter: "all")
    expect(page).to have_content("Unconfirmed proposal")
    expect(page).to have_content("Confirmed proposal")

    visit admin_hidden_proposals_path(filter: "with_confirmed_hide")
    expect(page).not_to have_content("Unconfirmed proposal")
    expect(page).to have_content("Confirmed proposal")
  end

  scenario "Action links remember the pagination setting and the filter" do
    allow(Proposal).to receive(:default_per_page).and_return(2)
    4.times { create(:proposal, :hidden, :with_confirmed_hide) }

    visit admin_hidden_proposals_path(filter: "with_confirmed_hide", page: 2)

    click_on("Restore", match: :first, exact: true)

    expect(current_url).to include("filter=with_confirmed_hide")
    expect(current_url).to include("page=2")
  end
end
