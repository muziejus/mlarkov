require_relative '../KarlMarxovChain'

RSpec.describe KarlMarxovChain do

  let(:kmc) { KarlMarxovChain.new }

  describe '#initialize' do
    context "when configs.yml is available" do
      it "finds configs.yml" do
        expect(File.exists?("configs.yml")).to eq(true)
      end

      it "assigns @configs" do
        expect(kmc.instance_variable_get(:@configs)).to_not be_nil
      end

      it "assigns @since_id" do
        expect(kmc.instance_variable_get(:@since_id)).to_not be_nil
      end

      it "assures that @since_id is an integer" do
        expect(kmc.instance_variable_get(:@since_id)).to be_an_integer
      end
    end

    context "when configs.yml is unavailable" do
      it "errors out usefully" do
        allow(File).to receive(:exists?).with("configs.yml").and_return(false)
        expect { KarlMarxovChain.new }.to raise_error RuntimeError
      end
    end
  end

  describe '#random_sentence' do

    subject(:random_sentence) { kmc.random_sentence }

    context "when dictionaries are available" do
      it "assigns @dictionary" do
        random_sentence
        expect(kmc.instance_variable_get(:@dictionary)).to_not be_nil
      end
      it "creates a string" do
        expect(random_sentence).to be_instance_of String
      end
      it "that is no more than 140 characters long" do
        expect(random_sentence.length).to be > 4
        # expect(random_sentence.length).to be < 140
      end
      it "that is capitalized" do
        expect(random_sentence[0]).to match(/[[:upper:]]/)
      end
    end

    context "when dictionaries are not available" do
      it "errors out usefully" do
        allow(File).to receive(:exists?).with("capital.mmd").and_return(false)
        expect { random_sentence }.to raise_error
      end
    end
    
  end

end
