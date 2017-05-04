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

require "zeta_hunter/version"
require "zeta_hunter/error/error"

module ZetaHunter
  def parse_dist_file fname
    all_v_all_dists = {}
    seqs = []
    num_seqs = -1
    File.open(fname, "rt").each_line.with_index do |line, idx|
      if idx.zero?
        num_seqs = line.chomp.to_i
      else
        seq, *these_dists = line.chomp.split "\t"
        seq.strip!
        these_dists.map!(&:to_f)

        seqs << seq

        if these_dists.empty?
          all_v_all_dists[seq] = { seq => 0.0 }
        else
          these_dists.each_with_index do |dist, dist_i|

            if dist_i.zero?
              all_v_all_dists[seq] = { seq => 0.0 }
            end

            other_seq = seqs[dist_i]
            all_v_all_dists[seq][other_seq] = dist
            all_v_all_dists[other_seq][seq] = dist
          end
        end
      end
    end

    unless all_v_all_dists.count == num_seqs
      abort "Dists count must equal num_seqs"
    end

    bool = all_v_all_dists.values.map(&:count).
           all? { |count| count == num_seqs }
    unless bool
      abort "The values of dists are incorrect"
    end

    all_v_all_dists
  end

  # Given the DB seqs info file, return a hash tables with OTU =>
  # [seqs] and seq => otu.
  def otus_from_otu_info_file info_f
    otu2seqs = {}
    seq2otu = {}
    File.open(info_f).each_line do |line|
      unless line.start_with? "#"
        acc, otu, *rest = line.chomp.split "\t"

        seq2otu[acc] = otu

        if otu2seqs.has_key? otu
          otu2seqs[otu] << acc
        else
          otu2seqs[otu] = [acc]
        end
      end
    end

    [otu2seqs, seq2otu]
  end

  def calc_auto_otu_sim otus, dists, default_sim
    otu_sim_info = {}
    otus.each do |otu, seqs|
      if seqs.count == 1
        mean_sim = default_sim
        min_sim = default_sim
      else
        in_otu_dists = []
        seqs.combination(2).each do |s1, s2|
          dist = dists[s1][s2]

          in_otu_dists << dist
        end

        mean_sim =
          (100 - (in_otu_dists.reduce(:+) / in_otu_dists.count * 100)).round

        min_sim =
          (100 - (in_otu_dists.max * 100)).round

      end

      otu_sim_info[otu] = { mean: mean_sim, min: min_sim }
    end

    otu_sim_info
  end

  def find_otu_sim auto_otu_sim, type, seq2otu, seq
    unless type == :mean || type == :min
      raise Error::ArgumentError, "Incorrect type (#{type})"
    end

    unless seq2otu.has_key? seq
      raise Error::ArgumentError, "seq '#{seq}' is not in seq2otu.keys"
    end

    otu = seq2otu[seq]

    unless auto_otu_sim.has_key? otu
      raise Error::StandardError, "otu '#{otu}' is not in auto_otu_sim.keys"
    end

    auto_otu_sim[otu][type]
  end

  def clean_str str
    str.strip.gsub(/[^\p{Alnum}_]+/, "_").gsub(/_+/, "_")
  end
end
