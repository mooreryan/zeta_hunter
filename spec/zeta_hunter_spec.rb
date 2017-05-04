# Copyright 2015 - 2017 Ryan Moore
# Contact: moorer@udel.edu
#
# This file is part of ZetaHunter.
#
# ZetaHunter is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ZetaHunter is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ZetaHunter.  If not, see <http://www.gnu.org/licenses/>.

require "spec_helper"

RSpec.describe ZetaHunter do
  it "has a version number" do
    expect(ZetaHunter::VERSION).not_to be nil
  end

  let(:klass) { c = Class.new; c.extend ZetaHunter }
  let(:otu2seqs) { { "otu1" => %w[seq1 seq2 seq3], "otu2" => %w[seq4] } }
  let(:seq2otu) { { "seq1" => "otu1",
                    "seq2" => "otu1",
                    "seq3" => "otu1",
                    "seq4" => "otu2" } }
  let(:dists) do
    { "seq1" => { "seq1" => 0.0,
                  "seq2" => 0.2,
                  "seq3" => 0.4,
                  "seq4" => 0.25 },
      "seq2" => { "seq1" => 0.2,
                  "seq2" => 0.0,
                  "seq3" => 0.3,
                  "seq4" => 0.35 },
      "seq3" => { "seq1" => 0.4,
                  "seq2" => 0.3,
                  "seq3" => 0.0,
                  "seq4" => 1 },
      "seq4" => { "seq1" => 0.25,
                  "seq2" => 0.35,
                  "seq3" => 1,
                  "seq4" => 0.0 } }
  end

  let(:auto_otu_sim) {
    { "otu1" => { mean: 70, min: 60 },
      "otu2" => { mean: 97, min: 97 } }
  }

  describe "#parse_dist_file" do
    let(:dist_f) { File.join SpecHelper::TEST_FILE_D, "seqs.dist" }

    it "returns a hash with all v all dists" do
      expect(klass.parse_dist_file dist_f).to eq dists
    end
  end

  describe "#otus_from_otu_info_file" do
    let(:info_f) { File.join SpecHelper::TEST_FILE_D, "otu_info.txt" }

    it "returns a hash with otu => [seq ids]" do
      expect(klass.otus_from_otu_info_file info_f).to eq [otu2seqs,
                                                          seq2otu]
    end
  end

  describe "#calc_auto_otu_sim" do
    it "returns mean and min similarity for OTU groups" do
      expect(klass.calc_auto_otu_sim otu2seqs, dists).to eq auto_otu_sim
    end
  end

  describe "#find_otu_sim" do
    context "when type is invalid" do
      it "raises an error" do
        seq = "seq1"

        expect { klass.find_otu_sim auto_otu_sim, :bad_type, seq2otu, seq }.
          to raise_error ZetaHunter::Error::ArgumentError
      end
    end

    context "when seq is not in seq2otu" do
      it "raises error" do
        seq = "apple"
        type = :mean

        expect { klass.find_otu_sim auto_otu_sim, type, seq2otu, seq }.
          to raise_error ZetaHunter::Error::ArgumentError
      end
    end

    context "when auto_otu_sim doesn't have the OTU" do
      it "raises an error" do
        seq = "seq1"
        type = :mean
        bad_otu_sim = {}

        expect { klass.find_otu_sim bad_otu_sim, type, seq2otu, seq }.
          to raise_error ZetaHunter::Error::StandardError
      end
    end


    context "when everything is fine" do
      it "returns OTU sim for a sequence given its OTU" do
        seq = "seq1"
        type = :mean
        sim = 70

        expect(klass.find_otu_sim auto_otu_sim, type, seq2otu, seq).to eq sim
      end
    end
  end
end
