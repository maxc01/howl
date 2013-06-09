import ActionBuffer, style from howl.ui
import Scintilla from howl

describe 'ActionBuffer', ->
  sci = Scintilla!
  buf = ActionBuffer sci
  sci.listener = buf.sci_listener

  before_each -> buf.text = ''

  it 'initialization takes an optional sci parameter', ->
    assert.not_error -> ActionBuffer!
    assert.equal ActionBuffer(sci).sci, sci

  it 'behaves like a Buffer', ->
    buf.text = 'hello'
    assert.equal buf.text, 'hello'
    buf\append ' world'
    assert.equal buf.text, 'hello world'

  describe '.insert(object, pos[ , style])', ->

    context 'with no specified style', ->

      it 'inserts the object with no specific style and returns the next position', ->
        assert.equals 6, buf\insert 'hello', 1
        assert.equal style.at_pos(buf, 1), 'unstyled'

    context 'with style specified', ->

      it 'styles the object with the specified style', ->
        buf.text = '˫˫'
        buf\insert 'hƏllo', 2, 'keyword'
        assert.equal 'unstyled', (style.at_pos(buf, 1))
        assert.equal 'keyword', (style.at_pos(buf, 2))
        assert.equal 'keyword', (style.at_pos(buf, 6))
        assert.equal 'unstyled', (style.at_pos(buf, 7))

      it 'styles the text with the default style if the style is unknown', ->
        buf\insert 'hello', 1, 'what?'
        assert.equal style.at_pos(buf, 1), 'default'

    context 'when object is a Chunk', ->
      it 'inserts the corresponding text and returns the next position', ->
        buf\insert 'foo', 1
        chunk = buf\chunk(1, 3)
        assert.equal 7, buf\insert chunk, 4
        assert.equal 'foofoo', buf.text

      it 'styles the inserted text using the same styling as for the chunk', ->
        buf\insert 'foo', 1, 'keyword'
        buf\insert 'bar', 4, 'number'
        chunk = buf\chunk(1, 6)
        buf\insert chunk, 7
        assert.equal 'foobarfoobar', buf.text
        chunk = buf\chunk(7, 12)
        assert.equal 'keyword', (style.at_pos(buf, 7))
        assert.equal 'number', (style.at_pos(buf, 10))

  describe '.append(text, style)', ->

    context 'with no specified style', ->

      it 'appends the text with no specific style and returns the next position', ->
        buf.text = 'hello'
        assert.equal #'hello world' + 1, buf\append ' world'
        assert.equal style.at_pos(buf, 7), 'unstyled'

    context 'with style specified', ->

      it 'styles the text with the specified style', ->
        buf.text = '˫'
        buf\append 'hƏllo', 'keyword'
        assert.equal style.at_pos(buf, 1), 'unstyled'
        assert.equal style.at_pos(buf, 2), 'keyword'
        assert.equal style.at_pos(buf, 6), 'keyword'

      it 'styles the text with the default style if the style is unknown', ->
        buf\append 'again', 'what?'
        assert.equal 'default', (style.at_pos(buf, buf.length - 1))

    context 'when object is a Chunk', ->
      it 'appends the corresponding text and returns the next position', ->
        buf\insert 'foo', 1
        chunk = buf\chunk(1, 3)
        assert.equals 7, buf\append chunk
        assert.equal 'foofoo', buf.text

      it 'styles the inserted text using the same styling as for the chunk', ->
        buf\insert 'foo', 1, 'keyword'
        buf\insert 'bar', 4, 'number'
        chunk = buf\chunk(1, 6)
        buf\append chunk
        assert.equal 'foobarfoobar', buf.text
        chunk = buf\chunk(7, 12)
        assert.equal 'keyword', (style.at_pos(buf, 7))
        assert.equal 'number', (style.at_pos(buf, 10))

  describe 'style(start_pos, end_pos, style)', ->
    it 'applies <style> for the inclusive text range given', ->
      buf.text = 'hƏlɩo'
      buf\style 2, 4, 'keyword'
      assert.equal style.at_pos(buf, 1), 'unstyled'
      assert.equal style.at_pos(buf, 2), 'keyword'
      assert.equal style.at_pos(buf, 4), 'keyword'
      assert.equal style.at_pos(buf, 5), 'unstyled'
