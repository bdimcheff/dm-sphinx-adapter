require 'test_adapter'

class TestClient < TestAdapter
  def test_initialize
    assert_nothing_raised { DataMapper::SphinxClient.new(@config) }
  end

  def test_index
    client = DataMapper::SphinxClient.new(@config)
    assert_nothing_raised{ client.index }
    assert_nothing_raised{ client.index 'items' }
    assert_nothing_raised{ client.index '*' }
    assert_nothing_raised{ client.index ['items', 'items_delta'] }
  end

  def test_managed_initialize
    assert_nothing_raised { DataMapper::SphinxManagedClient.new(@config) }
  end

  def test_search
    begin
      client = DataMapper::SphinxManagedClient.new(@config)
      client.index
      assert match = client.search('two')
      assert_equal 1, match[:total]
      assert_equal 2, match[:matches][0][:doc]
    ensure
      client.stop
    end
  end
end # TestClient
