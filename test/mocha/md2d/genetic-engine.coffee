helpers = require '../../helpers'
helpers.setupBrowserEnvironment()

GeneticEngine = requirejs 'md2d/models/engine/genetic-engine'
Model         = requirejs 'md2d/models/modeler'

describe "GeneticEngine", ->
  describe "[basic tests of the class]", ->
    describe "GeneticEngine constructor", ->
      it "should exist", ->
        should.exist GeneticEngine

      it "should act as a constructor", ->
        geneticEngine = new GeneticEngine(new Model {})
        should.exist geneticEngine

    describe "GeneticEngine instance", ->
      model = null
      geneticEngine = null
      mock =
        changeListener: ->
        transitionListener: ->
          # Call transitionEdned after each transition! It's required, as
          # geneticEngine will enqueue new transitions as long as some
          # transition is thought to be in progress.
          geneticEngine.transitionEnded()

      before ->
        model = new Model {}
        geneticEngine = model.geneticEngine()

      beforeEach ->
        sinon.spy mock, "changeListener"
        sinon.spy mock, "transitionListener"
        geneticEngine.on "change", mock.changeListener
        geneticEngine.on "transition", mock.transitionListener

      afterEach ->
        mock.changeListener.restore()
        mock.transitionListener.restore()

      it "should calculate DNA complement after setting DNA and dispatch appropriate event", ->
        mock.changeListener.callCount.should.eql 0
        model.set "DNA", "ATGC"
        model.get("DNAComplement").should.eql "TACG"
        mock.changeListener.callCount.should.eql 1
        mock.transitionListener.callCount.should.eql 0

      it "should calculate nucleotides arrays for DNA and DNA Complement", ->
        check = (d, idx, type) ->
          d[idx].idx.should.eql idx
          d[idx].type.should.eql type

        d = geneticEngine.DNANucleotides()
        check d, 0, "A"
        check d, 1, "T"
        check d, 2, "G"
        check d, 3, "C"
        d = geneticEngine.DNACompNucleotides()
        check d, 0, "T"
        check d, 1, "A"
        check d, 2, "C"
        check d, 3, "G"

      it "should calculate mRNA when state is set to 'transcription-end' or 'translation'", ->
        model.set "geneticEngineState", "transcription-end"
        model.get("mRNA").should.eql "AUGC"
        mock.changeListener.callCount.should.eql 1
        mock.transitionListener.callCount.should.eql 0

      it "should perform single step of DNA to mRNA transcription", ->
        model.set "geneticEngineState", "dna"
        model.get("mRNA").should.eql ""
        geneticEngine.transcribeStep()
        model.get("mRNA").should.eql ""   # DNA separated, mRNA prepared for transcription
        geneticEngine.transcribeStep()
        model.get("mRNA").should.eql "A"
        geneticEngine.transcribeStep("A") # Wrong, "U" is expected!
        model.get("mRNA").should.eql "A"  # Nothing happens, mRNA is still the same.
        geneticEngine.transcribeStep("U") # This time expected nucleotide is correct,
        model.get("mRNA").should.eql "AU" # so it's added to mRNA.

      it "should transcribe mRNA from DNA and dispatch appropriate events", ->
        model.set "geneticEngineState", "dna"
        model.set {DNA: "ATGC"}
        geneticEngine.transitionTo("transcription-end")
        mock.transitionListener.callCount.should.eql 5 # separation + 4 x transcription

        model.get("mRNA").should.eql "AUGC"

      it "shouldn't allow setting geneticEngineState to translation:x, where x > 0", ->
        model.set "geneticEngineState", "translation:15"
        # Expect fallback state: translation:0.
        model.get("geneticEngineState").should.eql "translation:0"

      it "should allow jumping to the next state", ->
        model.set "DNA", "ATGC" # so transcription and translation will be short
        model.set "geneticEngineState", "intro-cells"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "intro-zoom1"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "intro-zoom2"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "intro-zoom3"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "intro-polymerase"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "dna"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "transcription:0"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "transcription:1"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "transcription:2"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "transcription:3"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "transcription-end"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "after-transcription"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "before-translation"
        geneticEngine.jumpToNextState()
        model.get("geneticEngineState").should.eql "translation:0"
        # and that's all, for now it isn't permitted to jump to translation:x, where x > 0.

      it "should allow jumping to the previous state", ->
        # make things more interesting and start from translation-end
        geneticEngine.transitionToNextState();
        model.get("geneticEngineState").should.eql "translation:1"
        geneticEngine.transitionToNextState();
        model.get("geneticEngineState").should.eql "translation-end"

        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "translation:0"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "before-translation"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "after-transcription"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "transcription-end"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "transcription:3"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "transcription:2"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "transcription:1"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "transcription:0"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "dna"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "intro-polymerase"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "intro-zoom3"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "intro-zoom2"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "intro-zoom1"
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "intro-cells"
        # make sure that this won't break anything:
        geneticEngine.jumpToPrevState();
        model.get("geneticEngineState").should.eql "intro-cells"

      it "should provide state() helper methods", ->
        model.set "geneticEngineState", "transcription-end"
        state = geneticEngine.state()
        state.name.should.eql "transcription-end"
        isNaN(state.step).should.be.true

        model.set "geneticEngineState", "transcription:15"
        state = geneticEngine.state()
        state.name.should.eql "transcription"
        state.step.should.eql 15

      it "should provide stateBefore() and stateAfter() helper methods", ->
        model.set "geneticEngineState", "intro-cells"
        geneticEngine.stateBefore("dna").should.be.true
        geneticEngine.stateAfter("dna").should.be.false

        model.set "geneticEngineState", "transcription"
        geneticEngine.stateBefore("dna").should.be.false
        geneticEngine.stateAfter("dna").should.be.true
        geneticEngine.stateBefore("translation").should.be.true
        geneticEngine.stateAfter("translation").should.be.false
        geneticEngine.stateBefore("translation:15").should.be.true
        geneticEngine.stateAfter("translation:15").should.be.false

        model.set "geneticEngineState", "transcription:15"
        geneticEngine.stateBefore("transcription:14").should.be.false
        geneticEngine.stateAfter("transcription:14").should.be.true
        geneticEngine.stateBefore("transcription:15").should.be.false
        geneticEngine.stateAfter("transcription:15").should.be.false
        geneticEngine.stateBefore("transcription:16").should.be.true
        geneticEngine.stateAfter("transcription:16").should.be.false