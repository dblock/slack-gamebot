require 'spec_helper'

describe 'Website assets', :js, type: :feature do
  let!(:game) { Fabricate(:game, name: 'pong') }

  it 'loads content-versioned images, generated styles and scripts on visit and reload' do
    visit '/?version=1'

    2.times do
      icon = "/img/pong.png?v=#{Digest::SHA256.file('public/img/pong.png').hexdigest}"
      expect(page).to have_css("img[src='#{icon}']")
      expect(page.evaluate_script('typeof jQuery')).to eq 'function'
      expect(page.evaluate_script('Array.from(document.images).filter(img => img.getAttribute("src").startsWith("/")).every(img => img.complete && img.naturalWidth > 0)')).to be true
      expect(page.evaluate_script('Array.from(document.styleSheets).some(sheet => sheet.href && /\\/css\\/agency\\.css\\?v=[a-f0-9]{64}$/.test(sheet.href) && sheet.cssRules.length > 0)')).to be true
      expect(page.evaluate_script('getComputedStyle(document.querySelector("header")).backgroundImage')).to include("/img/header-bg.jpg?v=#{Digest::SHA256.file('public/img/header-bg.jpg').hexdigest}")
      page.refresh
    end
  end
end
