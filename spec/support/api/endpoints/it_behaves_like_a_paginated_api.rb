shared_examples_for 'a paginated api' do |model|
  let(:model_s) { model.name.underscore.to_sym }
  let(:model_ps) { model.name.underscore.pluralize.to_sym }
  context model.name do
    before do
      5.times { Fabricate(model_s) }
    end

    it 'returns 3 items by default' do
      expect(client.send(model_ps, {}).count).to eq 3
    end

    it 'returns 2 items' do
      expect(client.send(model_ps, size: 2).count).to eq 2
    end

    it 'returns pagination' do
      response = client.send(model_ps, size: 2, page: 2)
      expect(response._links.next._url).to eq "http://example.org/#{model_ps}?page=3&size=2"
      expect(response._links.prev._url).to eq "http://example.org/#{model_ps}?page=1&size=2"
      expect(response._links.self._url).to eq "http://example.org/#{model_ps}?page=2&size=2"
    end

    it 'returns all unique ids' do
      instances = client.send(model_ps, {})
      expect(instances.map(&:id).uniq.count).to eq 3
    end
  end
end
