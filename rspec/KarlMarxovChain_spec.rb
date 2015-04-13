require_relative '../KarlMarxovChain'

RSpec.describe KarlMarxovChain do

  let(:kmc) { KarlMarxovChain.new }

  describe '#initialize' do
    context "when configs.yml is available" do
      it "assigns @configs" do
        expect(kmc.instance_variable_get(:@configs)).to_not be_nil
      end

      it "assigns @since_id" do
        expect(kmc.instance_variable_get(:@since_id)).to_not be_nil
      end
    end
    context "when configs.yml is unavailable" do
      it "errors out usefully"
    end
  end

  describe '#random_sentence' do
    it "creates a random sentence"
    it "that is no more than 140 characters long"
    it "creates a sentence that is capitalized"
  end
end
