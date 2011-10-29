
def natural_numbers
  Enumerator.new do |y|
    number = 0
    loop do
      number += 1
      y.yield number
    end
  end
end

class GroupElement
  attr_accessor :group, :representation
  def initialize group, rep
    self.representation = rep
    self.group = group
  end
  include Comparable
  def <=> o
    self.representation <=> o.representation
  end

  def * other
    group.combine self, other
  end

  def ^ n
    [self].cycle.take(n).inject(group.neutral) {|a,b| a*b}
  end

  def order
    natural_numbers.detect {|n| self^n == group.neutral}
  end

  def neutral?
    self.group.neutral? self
  end


  def to_s
    representation.to_s
  end
end

class GroupOperation
  def [] a,b
    raise "abstract"
  end
end

class Circ < GroupOperation
  def [] a,b
    b.collect {|e| a[e]}
  end
end

class ModuloAdd < GroupOperation
  attr_accessor :n
  def initialize n
    self.n = n
  end

  def [] a,b
    (a+b)%n
  end
end

class SetOp < GroupOperation
  def initialize op
    @op = op
  end
  
  def [] a,b
    out = []
    a.each do |q|
      b.each do |p|
	out |= [q*p]
      end
    end
    out
  end
end
    
class GroupTable < GroupOperation
  def initialize set
    @map = {}
    set.each {|e| @map[e] = {}}
  end

  def []= a,b,c
    @map[a][b] = c
  end

  def [] a,b
    @map[a][b]
  end
end

class Group
  attr_reader :set, :operation
  attr_reader :neutral
  def initialize set, operation
    self.set = {}
    set.each {|e| self.set[e] = GroupElement.new(self, e)}
    self.operation = operation
    self.neutral = find_neutral
    close_set
  end

  def order
    self.set.size
  end

  def representations
    self.set.keys.sort rescue set.keys
  end
  
  def elements 
    self.set.values
  end

  def subgroup elts
    Group.new(elts, operation)
  end

  def == o
    return false unless  representations == o.representations
    set.keys.each do |a|
      set.keys.each do |b|
	return false unless operation[a,b] == o.operation[a,b]
      end
    end
    true
  end

  def subgroups
    s = []
    (1..order).select{|i| order%i == 0}.each do |i|
      self.set.keys.combination(i).each do |comb|
	s |= [comb]
      end
    end
    s
  end

  def combine a,b
    res = self.operation[a.representation,b.representation]
    set[res] = GroupElement.new(self,res) if set[res] == nil
    set[res] 
  end

  def [] a
    self.set[a]
  end

  def neutral? a
    self.set.values.all? {|e| e*a == e}
  end

  def to_s
    "<Group {#{self.representations.collect(&:to_s).join(",")}}>"
  end

  def / elts #BUGGY & slow
    s = subgroup(elts).elements
    nelts = []
    elements.each do |a| 
      nelts |= [s.collect{|b| a*b}.sort]
    end
    Group.new(nelts, SetOp.new(operation))
  end
  private
  attr_writer :set, :operation
  attr_writer :neutral

  def find_neutral
    self.set.values.detect {|e| neutral?(e)}
  end


  def close_set
    oset = nil
    nset = self.set.values
    while oset != nset
      oset,nset = nset, []
      oset.each do |v| 
	oset.each do |w|
	  nset |= [v, w, v*w]
	end
      end
    end
    nset.each {|e| set[e.representation] = e}
  end


end

def Z n
  Group.new((0...n), ModuloAdd.new(n))
end

def S n
  Group.new((0...n).to_a.permutation, Circ.new)
end

def test
  a = S 3
  b = a.subgroup [[0,2,1],[1,0,2]]
  raise "Not comparing correctly" unless a == b
end

test
